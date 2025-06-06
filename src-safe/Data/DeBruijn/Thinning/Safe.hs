{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE ExplicitNamespaces #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE RecordWildCards #-}

module Data.DeBruijn.Thinning.Safe (
  -- * Thinnings
  (:<=) (KeepAll, KeepOne, DropOne),
  toSafe,
  fromSafe,
  dropAll,
  toBools,
  fromTh,
  fromThRaw,

  -- * Existential Wrapper
  SomeTh (..),
  fromBools,
  toSomeTh,
  toSomeThRaw,
  fromSomeTh,
  fromSomeThRaw,

  -- * The action of thinnings on 'Nat'-indexed types
  Thin (..),

  -- * Specialised target for conversion
  ThRep,
) where

import Control.DeepSeq (NFData (..))
import Data.Bits (Bits (..))
import Data.DeBruijn.Index.Safe (Ix (..), isPos)
import Data.DeBruijn.Thinning.Fast (ThRep)
import Data.DeBruijn.Thinning.Fast qualified as Fast
import Data.Kind (Constraint, Type)
import Data.Type.Equality (type (:~:) (Refl))
import Data.Type.Nat (Nat (..), Pos, Pred)
import Data.Type.Nat.Singleton.Fast (SNatRep)
import Data.Type.Nat.Singleton.Safe (SNat (..), SomeSNat (..), decSNat, fromSNat, toSomeSNat)

--------------------------------------------------------------------------------
-- Thinnings
--------------------------------------------------------------------------------

-- | @n ':<=' m@ is the type of thinnings from @m@ to @n@.
type (:<=) :: Nat -> Nat -> Type
data (:<=) n m where
  KeepAll :: n :<= n
  KeepOne_ :: n :<= m -> S n :<= S m
  DropOne :: n :<= m -> n :<= S m

keepOne :: n :<= m -> S n :<= S m
keepOne KeepAll = KeepAll
keepOne n'm' = KeepOne_ n'm'

pattern KeepOne :: () => (Pos n, Pos m) => Pred n :<= Pred m -> n :<= m
pattern KeepOne n'm' <- KeepOne_ n'm' where KeepOne n'm' = keepOne n'm'

{-# COMPLETE KeepAll, KeepOne, DropOne #-}

deriving stock instance Eq (n :<= m)

instance Show (n :<= m) where
  showsPrec :: Int -> n :<= m -> ShowS
  showsPrec p =
    showParen (p > 10) . \case
      KeepAll -> showString "KeepAll"
      KeepOne n'm' -> showString "KeepOne " . showsPrec 11 n'm'
      DropOne nm' -> showString "DropOne " . showsPrec 11 nm'

instance NFData (n :<= m) where
  rnf :: n :<= m -> ()
  rnf KeepAll = ()
  rnf (KeepOne n'm') = rnf n'm'
  rnf (DropOne nm') = rnf nm'

-- | Convert from the efficient representation 'Fast.:<=' to the safe representation ':<='.
toSafe :: n Fast.:<= m -> n :<= m
toSafe = \case
  Fast.KeepAll -> KeepAll
  Fast.KeepOne n'm' -> KeepOne (toSafe n'm')
  Fast.DropOne nm' -> DropOne (toSafe nm')

-- | Convert from the safe representation ':<=' to the efficient representation 'Fast.:<='.
fromSafe :: n :<= m -> n Fast.:<= m
fromSafe = \case
  KeepAll -> Fast.KeepAll
  KeepOne n'm' -> Fast.KeepOne (fromSafe n'm')
  DropOne nm' -> Fast.DropOne (fromSafe nm')

-- | Drop all entries.
dropAll :: SNat m -> Z :<= m
dropAll Z = KeepAll
dropAll (S m') = DropOne (dropAll m')

-- | Convert a thinning into a list of booleans.
toBools :: n :<= m -> [Bool]
toBools = \case
  KeepAll -> []
  KeepOne n'm' -> False : toBools n'm'
  DropOne nm' -> True : toBools nm'

-- | Convert a thinning into a bit sequence.
fromTh :: (Bits bs) => n :<= m -> bs
fromTh = \case
  KeepAll -> zeroBits
  KeepOne n'm' -> (`unsafeShiftL` 1) . fromTh $ n'm'
  DropOne nm' -> (`setBit` 0) . (`unsafeShiftL` 1) . fromTh $ nm'
{-# SPECIALIZE fromTh :: n :<= m -> ThRep #-}

fromThRaw :: n :<= m -> ThRep
fromThRaw = fromTh

--------------------------------------------------------------------------------
-- Existential Wrapper
--------------------------------------------------------------------------------

data SomeTh
  = forall n m.
  SomeTh
  { lower :: SNat n
  , upper :: SNat m
  , value :: n :<= m
  }

instance Eq SomeTh where
  (==) :: SomeTh -> SomeTh -> Bool
  SomeTh n1 m1 n1m1 == SomeTh n2 m2 n2m2
    | Just Refl <- decSNat n1 n2
    , Just Refl <- decSNat m1 m2 =
        n1m1 == n2m2
    | otherwise = False

deriving stock instance Show SomeTh

instance NFData SomeTh where
  rnf :: SomeTh -> ()
  rnf SomeTh{..} = rnf lower `seq` rnf upper `seq` rnf value

someKeepAll :: SomeSNat -> SomeTh
someKeepAll (SomeSNat bound) =
  SomeTh
    { lower = bound
    , upper = bound
    , value = KeepAll
    }

someKeepOne :: SomeTh -> SomeTh
someKeepOne SomeTh{..} =
  SomeTh
    { lower = S lower
    , upper = S upper
    , value = KeepOne value
    }

someDropOne :: SomeTh -> SomeTh
someDropOne SomeTh{..} =
  SomeTh
    { lower = lower
    , upper = S upper
    , value = DropOne value
    }

fromBools :: SomeSNat -> [Bool] -> SomeTh
fromBools bound = go
 where
  go [] = someKeepAll bound
  go (False : bools) = someKeepOne (go bools)
  go (True : bools) = someDropOne (go bools)

toSomeTh :: (Show i, Show bs, Integral i, Bits bs) => (i, bs) -> SomeTh
toSomeTh (nRep, nmRep)
  | nmRep == zeroBits = someKeepAll (toSomeSNat nRep)
  | testBit nmRep 0 = someDropOne (toSomeTh (nRep, unsafeShiftR nmRep 1))
  | otherwise = someKeepOne (toSomeTh (nRep - 1, unsafeShiftR nmRep 1))
{-# SPECIALIZE toSomeTh :: (SNatRep, ThRep) -> SomeTh #-}

toSomeThRaw :: (SNatRep, ThRep) -> SomeTh
toSomeThRaw = toSomeTh

withSomeTh :: (forall n m. SNat n -> SNat m -> n :<= m -> r) -> SomeTh -> r
withSomeTh action (SomeTh n m nm) = action n m nm

fromSomeTh :: (Integral i, Bits bs) => SomeTh -> (i, bs)
fromSomeTh = withSomeTh (\n _m nm -> (fromSNat n, fromTh nm))
{-# SPECIALIZE fromSomeTh :: SomeTh -> (SNatRep, ThRep) #-}

fromSomeThRaw :: SomeTh -> (SNatRep, ThRep)
fromSomeThRaw = fromSomeTh

--------------------------------------------------------------------------------
-- Thinning Class
--------------------------------------------------------------------------------

-- | The actions of thinnings on natural-indexed data types.
type Thin :: (Nat -> Type) -> Constraint
class Thin f where
  thin :: n :<= m -> f n -> f m
  thick :: n :<= m -> f m -> Maybe (f n)

instance Thin Ix where
  thin :: n :<= m -> Ix n -> Ix m
  thin !t !i = isPos i $
    case t of
      KeepAll -> i
      KeepOne n'm' ->
        case i of
          FZ -> FZ
          FS i' -> FS (thin n'm' i')
      DropOne nm' -> FS (thin nm' i)

  thick :: n :<= m -> Ix m -> Maybe (Ix n)
  thick KeepAll i = Just i
  thick (KeepOne _n'm') FZ = Just FZ
  thick (KeepOne n'm') (FS i') = FS <$> thick n'm' i'
  thick (DropOne _nm') FZ = Nothing
  thick (DropOne nm') (FS i') = thick nm' i'

instance Thin ((:<=) l) where
  thin :: n :<= m -> l :<= n -> l :<= m
  thin nm KeepAll = nm
  thin KeepAll ln = ln
  thin (KeepOne n'm') (KeepOne l'n') = KeepOne (thin n'm' l'n')
  thin (KeepOne n'm') (DropOne ln') = DropOne (thin n'm' ln')
  thin (DropOne nm') ln = DropOne (thin nm' ln)

  thick :: n :<= m -> l :<= m -> Maybe (l :<= n)
  thick KeepAll lm = Just lm
  thick (KeepOne n'm') KeepAll = KeepOne <$> thick n'm' KeepAll
  thick (KeepOne n'm') (KeepOne l'n') = KeepOne <$> thick n'm' l'n'
  thick (KeepOne n'm') (DropOne ln') = DropOne <$> thick n'm' ln'
  thick (DropOne _nm') KeepAll = Nothing
  thick (DropOne _nm') (KeepOne _l'n') = Nothing
  thick (DropOne nm') (DropOne ln') = thick nm' ln'
