{-# LANGUAGE GADTs #-}
{-# LANGUAGE QuantifiedConstraints #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Data.DeBruijn.Index.Fast.Arbitrary (
  arbitraryIx,
) where

import Data.DeBruijn.Index.Arbitrary (SomeIxRep (..))
import Data.DeBruijn.Index.Fast (Ix (..), SomeIx (..), toSomeIxRaw)
import Data.Type.Nat (Nat (..))
import Data.Type.Nat.Singleton.Fast (SNat (..))
import Data.Type.Nat.Singleton.Fast.Arbitrary ()
import Test.QuickCheck.Arbitrary (Arbitrary (..))
import Test.QuickCheck.Gen (Gen, oneof)

instance Arbitrary SomeIx where
  arbitrary :: Gen SomeIx
  arbitrary = do
    SomeIxRep n i <- arbitrary
    pure $ toSomeIxRaw (n, i)

instance Arbitrary (Ix (S Z)) where
  arbitrary :: Gen (Ix (S Z))
  arbitrary = pure FZ

instance (forall m. Arbitrary (Ix (S m))) => Arbitrary (Ix (S (S n))) where
  arbitrary :: Gen (Ix (S (S n)))
  arbitrary = oneof [pure FZ, FS <$> arbitrary]

arbitraryIx :: SNat (S n) -> Gen (Ix (S n))
arbitraryIx (S Z) = pure FZ
arbitraryIx (S n@(S _)) = oneof [pure FZ, FS <$> arbitraryIx n]
