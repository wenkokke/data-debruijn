{-# LANGUAGE ExplicitNamespaces #-}
{-# LANGUAGE GADTs #-}

module Test.Data.DeBruijn.Index (tests) where

import Data.DeBruijn.Index.Arbitrary (SomeIxRep (..))
import Data.DeBruijn.Index.Fast (ixRepToSNatRep)
import Data.DeBruijn.Index.Fast qualified as Fast
import Data.DeBruijn.Index.Fast.Arbitrary ()
import Data.DeBruijn.Index.Safe (IxRep)
import Data.DeBruijn.Index.Safe qualified as Fast (fromSafe, toSafe)
import Data.DeBruijn.Index.Safe qualified as Safe
import Data.DeBruijn.Index.Safe.Arbitrary ()
import Data.Type.Equality (type (:~:) (Refl))
import Data.Type.Nat.Singleton.Safe (SNat (..), SNatRep)
import Data.Type.Nat.Singleton.Safe qualified as SNat.Fast (fromSafe, toSafe)
import Data.Type.Nat.Singleton.Safe qualified as Safe (SomeSNat (..), decSNat)
import Data.Type.Nat.Singleton.Safe.Arbitrary ()
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.QuickCheck (NonNegative (..), Positive (..), Property, Testable, collect, counterexample, once, testProperty)
import Text.Printf (printf)

tests :: TestTree
tests =
  testGroup
    "Test.DeBruijn.Data.Index"
    [ -- Test correspondence between Fast and Safe APIs
      testProperty "test_zeroIx" test_zeroIx
    , testProperty "test_succIx" test_succIx
    , testProperty "test_caseIx" test_caseIx
    , testProperty "test_eqIxEq" test_eqIxEq
    , testProperty "test_fromIxRawEq" test_fromIxRawEq
    , testProperty "test_fromIxEq" test_fromIxEq
    , testProperty "test_thinEq" test_thinEq
    , testProperty "test_thickEq" test_thickEq
    , testProperty "test_injectEq" test_injectEq
    , testProperty "test_raiseEq" test_raiseEq
    , testProperty "test_fromSomeIxEq" test_fromSomeIxEq
    , testProperty "test_fromSomeIxRawEq" test_fromSomeIxRawEq
    , testProperty "test_toSomeIxEq" test_toSomeIxEq
    , testProperty "test_toSomeIxRawEq" test_toSomeIxRawEq
    , -- Test conversion to/from numbers of Fast API
      testProperty "test_Fast_fromSomeIx_eq_fromSomeIxRaw" test_Fast_fromSomeIx_eq_fromSomeIxRaw
    , testProperty "test_Fast_toSomeIx_eq_toSomeIxRaw" test_Fast_toSomeIx_eq_toSomeIxRaw
    , testProperty "test_Fast_toSomeIxRaw_o_fromSomeIxRaw_eq_id" test_Fast_toSomeIxRaw_o_fromSomeIxRaw_eq_id
    , testProperty "test_Fast_fromSomeIxRaw_o_toSomeIxRaw_eq_id" test_Fast_fromSomeIxRaw_o_toSomeIxRaw_eq_id
    , -- Test conversion to/from numbers of Safe API
      testProperty "test_Safe_fromSomeIx_eq_fromSomeIxRaw" test_Safe_fromSomeIx_eq_fromSomeIxRaw
    , testProperty "test_Safe_toSomeIx_eq_toSomeIxRaw" test_Safe_toSomeIx_eq_toSomeIxRaw
    , testProperty "test_Safe_toSomeIxRaw_o_fromSomeIxRaw_eq_id" test_Safe_toSomeIxRaw_o_fromSomeIxRaw_eq_id
    , testProperty "test_Safe_fromSomeIxRaw_o_toSomeIxRaw_eq_id" test_Safe_fromSomeIxRaw_o_toSomeIxRaw_eq_id
    ]

--------------------------------------------------------------------------------
-- Test correspondence between Fast and Safe APIs
--------------------------------------------------------------------------------

-- | Test: Constructor @FZ@.
test_zeroIx :: Property
test_zeroIx =
  once $
    Safe.FZ == Fast.toSafe Fast.FZ

-- | Test: Constructor @FS@.
test_succIx :: Safe.SomeIx -> Property
test_succIx (Safe.SomeIx _ i) =
  collectMagnitude "i" (Safe.fromIxRaw i) $ do
    let expect = Safe.FS i
    let actual = Fast.toSafe (Fast.FS (Fast.fromSafe i))
    counterexample (printf "%s == %s" (show expect) (show actual)) $
      expect == actual

-- | Test: Case analysis.
test_caseIx :: Safe.SomeIx -> Property
test_caseIx (Safe.SomeIx _ i) =
  collectMagnitude "i" (Safe.fromIxRaw i) $
    case (i, Fast.fromSafe i) of
      (Safe.FZ, Fast.FZ) -> True
      (Safe.FS i', Fast.FS j') -> i' == Fast.toSafe j'
      _ -> False

-- | Test: @eqIx@.
test_eqIxEq :: Safe.SomeIx -> Safe.SomeIx -> Property
test_eqIxEq (Safe.SomeIx _ i) (Safe.SomeIx _ j) =
  collectMagnitude "i" (Safe.fromIxRaw i) $ do
    let expect = Safe.eqIx i j
    let actual = Fast.eqIx (Fast.fromSafe i) (Fast.fromSafe j)
    counterexample (printf "%s == %s" (show expect) (show actual)) $
      expect == actual

-- | Test: @fromIx@.
test_fromIxEq :: Safe.SomeIx -> Property
test_fromIxEq (Safe.SomeIx _ i) =
  collectMagnitude "i" (Safe.fromIxRaw i) $ do
    let expect = Safe.fromIx @Int i
    let actual = Fast.fromIx @Int (Fast.fromSafe i)
    counterexample (printf "%s == %s" (show expect) (show actual)) $
      expect == actual

-- | Test: @fromIxRaw@.
test_fromIxRawEq :: Safe.SomeIx -> Property
test_fromIxRawEq (Safe.SomeIx _ i) =
  collectMagnitude "i" (Safe.fromIxRaw i) $ do
    let expect = Safe.fromIxRaw i
    let actual = Fast.fromIxRaw (Fast.fromSafe i)
    counterexample (printf "%s == %s" (show expect) (show actual)) $
      expect == actual

-- | Test: @thin@.
test_thinEq :: (Positive SNatRep, NonNegative IxRep, NonNegative IxRep) -> Property
test_thinEq (Positive dRaw, NonNegative iRaw, NonNegative jRaw)
  | let nRaw = dRaw + ixRepToSNatRep (iRaw `max` jRaw)
  , Safe.SomeIx (S n) i <- Safe.toSomeIxRaw (nRaw + 1, iRaw)
  , Safe.SomeIx n' j <- Safe.toSomeIxRaw (nRaw, jRaw)
  , Just Refl <- Safe.decSNat n n' =
      collectMagnitude "i" (Safe.fromIxRaw i) $ do
        let expect = Safe.thin i j
        let actual = Fast.toSafe (Fast.thin (Fast.fromSafe i) (Fast.fromSafe j))
        counterexample (printf "%s == %s" (show expect) (show actual)) $
          expect == actual
  | otherwise = error "test_thinEq: could not construct test"

-- | Test: @thick@.
test_thickEq :: (Positive SNatRep, NonNegative IxRep, NonNegative IxRep) -> Property
test_thickEq (Positive dRaw, NonNegative iRaw, NonNegative jRaw)
  | let nRaw = dRaw + ixRepToSNatRep (iRaw `max` jRaw)
  , Safe.SomeIx (S n) i <- Safe.toSomeIxRaw (nRaw, iRaw)
  , Safe.SomeIx (S n') j <- Safe.toSomeIxRaw (nRaw, jRaw)
  , Just Refl <- Safe.decSNat n n' =
      collectMagnitude "i" (Safe.fromIxRaw i) $ do
        let expect = Safe.thick i j
        let actual = Fast.toSafe <$> Fast.thick (Fast.fromSafe i) (Fast.fromSafe j)
        counterexample (printf "%s == %s" (show expect) (show actual)) $
          expect == actual
  | otherwise = error "test_thinEq: could not construct test"

-- | Test: @inject@.
test_injectEq :: Safe.SomeIx -> Safe.SomeSNat -> Property
test_injectEq (Safe.SomeIx _ i) (Safe.SomeSNat m) =
  collectMagnitude "i" (Safe.fromIxRaw i) $ do
    let expect = Safe.inject i m
    let actual = Fast.toSafe (Fast.inject (Fast.fromSafe i) (SNat.Fast.fromSafe m))
    counterexample (printf "%s == %s" (show expect) (show actual)) $
      expect == actual

-- | Test: @raise@.
test_raiseEq :: Safe.SomeSNat -> Safe.SomeIx -> Property
test_raiseEq (Safe.SomeSNat n) (Safe.SomeIx _ j) =
  collectMagnitude "j" (Safe.fromIxRaw j) $ do
    let expect = Safe.raise n j
    let actual = Fast.toSafe (Fast.raise (SNat.Fast.fromSafe n) (Fast.fromSafe j))
    counterexample (printf "%s == %s" (show expect) (show actual)) $
      expect == actual

-- | Test: @fromSomeIx@.
test_fromSomeIxEq :: Safe.SomeIx -> Property
test_fromSomeIxEq (Safe.SomeIx n i) =
  collectMagnitude "i" (Safe.fromIxRaw i) $ do
    let expect = Safe.fromSomeIx @SNatRep @IxRep (Safe.SomeIx n i)
    let actual = Fast.fromSomeIx (Fast.SomeIx (SNat.Fast.fromSafe n) (Fast.fromSafe i))
    counterexample (printf "%s == %s" (show expect) (show actual)) $
      expect == actual

-- | Test: @fromSomeIxRaw@.
test_fromSomeIxRawEq :: Safe.SomeIx -> Property
test_fromSomeIxRawEq (Safe.SomeIx n i) =
  collectMagnitude "i" (Safe.fromIxRaw i) $ do
    let expect = Safe.fromSomeIxRaw (Safe.SomeIx n i)
    let actual = Fast.fromSomeIxRaw (Fast.SomeIx (SNat.Fast.fromSafe n) (Fast.fromSafe i))
    counterexample (printf "%s == %s" (show expect) (show actual)) $
      expect == actual

-- | Test: @toSomeIx@.
test_toSomeIxEq :: SomeIxRep -> Property
test_toSomeIxEq (SomeIxRep nRep iRep) =
  collectMagnitude "i" iRep $ do
    let expect = Safe.toSomeIx (nRep, iRep)
    let actual = Fast.toSomeIx (nRep, iRep)
    counterexample (printf "%s == %s" (show expect) (show actual)) $
      case (expect, actual) of
        (Safe.SomeIx n1 i1, Fast.SomeIx n2 i2) ->
          case n1 `Safe.decSNat` SNat.Fast.toSafe n2 of
            Just Refl -> i1 == Fast.toSafe i2
            Nothing -> False

-- | Test: @toSomeIxRaw@.
test_toSomeIxRawEq :: SomeIxRep -> Property
test_toSomeIxRawEq (SomeIxRep nRep iRep) =
  collectMagnitude "i" iRep $ do
    let expect = Safe.toSomeIxRaw (nRep, iRep)
    let actual = Fast.toSomeIxRaw (nRep, iRep)
    counterexample (printf "%s == %s" (show expect) (show actual)) $
      case (expect, actual) of
        (Safe.SomeIx n1 i1, Fast.SomeIx n2 i2) ->
          case n1 `Safe.decSNat` SNat.Fast.toSafe n2 of
            Just Refl -> i1 == Fast.toSafe i2
            Nothing -> False

--------------------------------------------------------------------------------
-- Test conversion to/from numbers of Fast API
--------------------------------------------------------------------------------

-- | Test: @fromSomeIx == fromSomeIxRaw@.
test_Fast_fromSomeIx_eq_fromSomeIxRaw :: Fast.SomeIx -> Property
test_Fast_fromSomeIx_eq_fromSomeIxRaw i =
  collectMagnitude "i" (fst $ Fast.fromSomeIxRaw i) $
    Fast.fromSomeIx i == Fast.fromSomeIxRaw i

-- | Test: @toSomeIx == toSomeIxRaw@.
test_Fast_toSomeIx_eq_toSomeIxRaw :: SomeIxRep -> Property
test_Fast_toSomeIx_eq_toSomeIxRaw (SomeIxRep nRep iRep) =
  collectMagnitude "i" iRep $
    Fast.toSomeIx (nRep, iRep) == Fast.toSomeIxRaw (nRep, iRep)

-- | Test: @toSomeIxRaw . fromSomeIxRaw == id@.
test_Fast_toSomeIxRaw_o_fromSomeIxRaw_eq_id :: Fast.SomeIx -> Property
test_Fast_toSomeIxRaw_o_fromSomeIxRaw_eq_id i =
  collectMagnitude "i" (fst $ Fast.fromSomeIxRaw i) $
    Fast.toSomeIxRaw (Fast.fromSomeIxRaw i) == i

-- | Test: @fromSomeIxRaw . toSomeIxRaw == id@.
test_Fast_fromSomeIxRaw_o_toSomeIxRaw_eq_id :: SomeIxRep -> Property
test_Fast_fromSomeIxRaw_o_toSomeIxRaw_eq_id (SomeIxRep nRep iRep) =
  collectMagnitude "i" iRep $
    Fast.fromSomeIxRaw (Fast.toSomeIxRaw (nRep, iRep)) == (nRep, iRep)

-- Corollary: @toSomeIx . fromSomeIx == id@.

-- Corollary: @fromSomeIx . toSomeIx == id@.

--------------------------------------------------------------------------------
-- Test conversion to/from numbers of Safe API
--------------------------------------------------------------------------------

-- | Test: @fromSomeIx == fromSomeIxRaw@.
test_Safe_fromSomeIx_eq_fromSomeIxRaw :: Safe.SomeIx -> Property
test_Safe_fromSomeIx_eq_fromSomeIxRaw i =
  collectMagnitude "i" (fst $ Safe.fromSomeIxRaw i) $
    Safe.fromSomeIx i == Safe.fromSomeIxRaw i

-- | Test: @toSomeIx == toSomeIxRaw@.
test_Safe_toSomeIx_eq_toSomeIxRaw :: SomeIxRep -> Property
test_Safe_toSomeIx_eq_toSomeIxRaw (SomeIxRep nRep iRep) =
  collectMagnitude "i" iRep $
    Safe.toSomeIx (nRep, iRep) == Safe.toSomeIxRaw (nRep, iRep)

-- | Test: @toSomeIxRaw . fromSomeIxRaw == id@.
test_Safe_toSomeIxRaw_o_fromSomeIxRaw_eq_id :: Safe.SomeIx -> Property
test_Safe_toSomeIxRaw_o_fromSomeIxRaw_eq_id i =
  collectMagnitude "i" (fst $ Safe.fromSomeIxRaw i) $
    Safe.toSomeIxRaw (Safe.fromSomeIxRaw i) == i

-- | Test: @fromSomeIxRaw . toSomeIxRaw == id@.
test_Safe_fromSomeIxRaw_o_toSomeIxRaw_eq_id :: SomeIxRep -> Property
test_Safe_fromSomeIxRaw_o_toSomeIxRaw_eq_id (SomeIxRep nRep iRep) =
  collectMagnitude "i" iRep $
    Safe.fromSomeIxRaw (Safe.toSomeIxRaw (nRep, iRep)) == (nRep, iRep)

-- Corollary: @toSomeIx . fromSomeIx == id@.

-- Corollary: @fromSomeIx . toSomeIx == id@.

--------------------------------------------------------------------------------
-- Helper functions.
--------------------------------------------------------------------------------

data Magnitude = Magnitude String Int

magnitudeBase :: Int
magnitudeBase = 2

instance Show Magnitude where
  show :: Magnitude -> String
  show (Magnitude name 0) =
    "value of " <> name <> " is 0"
  show (Magnitude name m) =
    "value of " <> name <> " is " <> show (magnitudeBase ^ pred m) <> "-" <> show (magnitudeBase ^ m)

collectMagnitude :: (Integral i, Testable prop) => String -> i -> prop -> Property
collectMagnitude name iRep = collect (Magnitude name . magnitude . fromIntegral $ iRep)
 where
  magnitude :: Int -> Int
  magnitude i = if i <= 0 then 0 else 1 + magnitude (i `div` magnitudeBase)
