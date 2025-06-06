{-# LANGUAGE ExplicitNamespaces #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE QuantifiedConstraints #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Data.DeBruijn.Thinning.Fast.Arbitrary (
  arbitraryTh,
) where

import Data.DeBruijn.Thinning.Arbitrary (SomeThRep (..))
import Data.DeBruijn.Thinning.Fast (SomeTh (..), dropAll, toSomeThRaw, type (:<=) (DropOne, KeepAll, KeepOne))
import Data.Proxy (Proxy (..))
import Data.Type.Equality (type (:~:) (Refl))
import Data.Type.Nat (type (+))
import Data.Type.Nat.Singleton.Fast (SNat (..), plusCommS, plusUnitR)
import Data.Type.Nat.Singleton.Fast.Arbitrary ()
import Test.QuickCheck.Arbitrary (Arbitrary (..))
import Test.QuickCheck.Gen (Gen, oneof)

instance Arbitrary SomeTh where
  arbitrary :: Gen SomeTh
  arbitrary = do
    SomeThRep n nm <- arbitrary
    pure $ toSomeThRaw (n, nm)

arbitraryTh :: SNat n -> SNat m -> Gen (n :<= (n + m))
arbitraryTh n Z = case plusUnitR n of Refl -> pure KeepAll
arbitraryTh Z m = pure (dropAll m)
arbitraryTh n@(S n') m@(S m') = oneof [keepOne, dropOne]
 where
  keepOne = KeepOne <$> arbitraryTh n' m
  dropOne = case plusCommS n' (erase m') of Refl -> DropOne <$> arbitraryTh n m'

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------

-- | @`erase` x@ erases the content of @x@ to a @`Proxy`@.
erase :: f a -> Proxy a
erase _ = Proxy
{-# INLINE erase #-}
