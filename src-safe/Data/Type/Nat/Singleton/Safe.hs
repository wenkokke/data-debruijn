{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE QuantifiedConstraints #-}
{-# LANGUAGE TypeFamilies #-}

module Data.Type.Nat.Singleton.Safe (
  -- * Natural Number Singletons
  SNat (..),
  toSafe,
  fromSafe,
  fromSNat,
  fromSNatRaw,
  plus,
  decSNat,

  -- * Existential Wrapper
  SomeSNat (..),
  withSomeSNat,
  toSomeSNat,
  toSomeSNatRaw,
  fromSomeSNat,
  fromSomeSNatRaw,

  -- * Laws
  plusUnitL,
  plusUnitR,
  plusCommS,
  plusComm,
  plusAssoc,

  -- * Linking Type-Level and Value-Level
  KnownNat (..),
  withKnownNat,

  -- * Specialised target for conversion
  SNatRep,
) where

import Control.DeepSeq (NFData (..))
import Data.Kind (Constraint, Type)
import Data.Maybe (isJust)
import Data.Proxy (Proxy (..))
import Data.Type.Equality (type (:~:) (Refl))
import Data.Type.Equality qualified as Eq
import Data.Type.Nat (Nat (..), type (+))
import Data.Type.Nat.Singleton.Fast (SNatRep)
import Data.Type.Nat.Singleton.Fast qualified as Fast

{- $setup
>>> import Data.Type.Nat.Singleton.Safe.Arbitrary
-}

--------------------------------------------------------------------------------
-- Natural Number Singletons
--------------------------------------------------------------------------------

-- | @'SNat' n@ is the singleton type for natural numbers.
type SNat :: Nat -> Type
data SNat n where
  Z :: SNat Z
  S :: SNat n -> SNat (S n)

instance Eq (SNat n) where
  (==) :: SNat n -> SNat n -> Bool
  m == n = isJust (decSNat m n)

instance Show (SNat n) where
  showsPrec :: Int -> SNat n -> ShowS
  showsPrec p = \case
    Z -> showString "Z"
    S n -> showParen (p > 10) $ showString "S " . showsPrec 11 n

instance NFData (SNat n) where
  rnf :: SNat n -> ()
  rnf Z = ()
  rnf (S n) = rnf n

-- | Convert from the efficient representation 'Fast.SNat' to the safe representation 'SNat'.
toSafe :: Fast.SNat n -> SNat n
toSafe Fast.Z = Z
toSafe (Fast.S n) = S (toSafe n)

-- | Convert from the safe representation 'SNat' to the efficient representation 'Fast.SNat'.
fromSafe :: SNat n -> Fast.SNat n
fromSafe Z = Fast.Z
fromSafe (S n) = Fast.S (fromSafe n)

-- | @'fromSNat' n@ returns the numeric representation of 'SNat n'.
fromSNat :: (Integral i) => SNat n -> i
fromSNat Z = 0
fromSNat (S n') = 1 + fromSNat n'
{-# SPECIALIZE fromSNat :: SNat n -> SNatRep #-}

fromSNatRaw :: SNat n -> SNatRep
fromSNatRaw = fromSNat
{-# INLINE fromSNatRaw #-}

-- | Addition for natural number singletons.
plus :: SNat n -> SNat m -> SNat (n + m)
Z `plus` m = m
S n `plus` m = S (n `plus` m)

-- | Decidable equality for natural number singletons.
decSNat :: SNat m -> SNat n -> Maybe (m :~: n)
decSNat Z Z = Just Refl
decSNat (S m') (S n') = (\Refl -> Refl) <$> decSNat m' n'
decSNat _m _n = Nothing

--------------------------------------------------------------------------------
-- Existential Wrapper
--------------------------------------------------------------------------------

-- | An existential wrapper around natural number singletons.
type SomeSNat :: Type
data SomeSNat = forall (n :: Nat). SomeSNat !(SNat n)

instance NFData SomeSNat where
  rnf :: SomeSNat -> ()
  rnf (SomeSNat n) = rnf n

deriving instance Show SomeSNat

instance Eq SomeSNat where
  (==) :: SomeSNat -> SomeSNat -> Bool
  SomeSNat m == SomeSNat n = isJust (decSNat m n)

-- | Evaluate a term with access to the underlying @'SNat'@.
withSomeSNat :: (forall n. SNat n -> a) -> SomeSNat -> a
withSomeSNat action (SomeSNat n) = action n

{-| @'toSomeSNat' n@ constructs the singleton @'SNat' n@.

prop> toSomeSNat (fromSomeSNat n) == n
-}
toSomeSNat :: (Integral i) => i -> SomeSNat
toSomeSNat n = iterate' n (withSomeSNat $ SomeSNat . S) (SomeSNat Z)

{-| @'toSomeSNat' n@ constructs the singleton @'SNat' n@.

prop> toSomeSNatRaw (fromSomeSNatRaw n) == n
-}
toSomeSNatRaw :: SNatRep -> SomeSNat
toSomeSNatRaw = toSomeSNat

-- | @'fromSomeSNat' n@ returns the numeric representation of the wrapped singleton.
fromSomeSNat :: (Integral i) => SomeSNat -> i
fromSomeSNat = withSomeSNat fromSNat

-- | @'fromSomeSNat' n@ returns the 'SNatRep' representation of the wrapped singleton.
fromSomeSNatRaw :: SomeSNat -> SNatRep
fromSomeSNatRaw = fromSomeSNat

--------------------------------------------------------------------------------
-- Laws
--------------------------------------------------------------------------------

plusUnitL :: Proxy n -> Z + n :~: n
plusUnitL _ = Refl

plusUnitR :: SNat n -> n + Z :~: n
plusUnitR Z = Refl
plusUnitR (S n') =
  case plusUnitR n' of
    Refl -> Refl

plusCommS :: SNat n -> Proxy m -> S (n + m) :~: n + S m
plusCommS Z _ = Refl
plusCommS (S n') m = Eq.apply Refl (plusCommS n' m)

plusComm :: SNat n -> SNat m -> n + m :~: m + n
plusComm Z m = Eq.sym (plusUnitR m)
plusComm (S n') m = Eq.apply Refl (plusComm n' m) `Eq.trans` plusCommS m (erase n')

plusAssoc :: SNat n -> Proxy m -> Proxy l -> (n + m) + l :~: n + (m + l)
plusAssoc Z _m _l = Refl
plusAssoc (S n') m l = Eq.apply Refl (plusAssoc n' m l)

--------------------------------------------------------------------------------
-- Linking Type-Level and Value-Level
--------------------------------------------------------------------------------

type KnownNat :: Nat -> Constraint
class KnownNat n where
  natSing :: SNat n

instance KnownNat Z where
  natSing :: SNat Z
  natSing = Z

instance (KnownNat n) => KnownNat (S n) where
  natSing :: SNat (S n)
  natSing = S natSing

withKnownNat :: SNat n -> ((KnownNat n) => r) -> r
withKnownNat Z action = action
withKnownNat (S n) action = withKnownNat n action

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------

-- | @`erase` x@ erases the content of @x@ to a @`Proxy`@.
erase :: f a -> Proxy a
erase _ = Proxy
{-# INLINE erase #-}

-- | @`iterate'` i f@ applies @f@ @i@ times.
iterate' :: (Integral i) => i -> (a -> a) -> a -> a
iterate' i f x
  | i <= 0 = x
  | otherwise = iterate' (i - 1) f $! f x
