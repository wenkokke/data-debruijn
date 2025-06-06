{-# LANGUAGE ExplicitNamespaces #-}
{-# LANGUAGE GADTs #-}

module Bench.Time.Data.DeBruijn.Index (
  benchmarks,
  bench_thickArgs,
) where

import Control.DeepSeq (force)
import Criterion.Main (Benchmark, bench, bgroup, nf)
import Data.DeBruijn.Index (IxRep, SomeIx (..), thick, thin, toSomeIxRaw)
import Data.List (nub)
import Data.Type.Equality (type (:~:) (Refl))
import Data.Type.Nat.Singleton (SNat (..), SNatRep, decSNat)
import Text.Printf (printf)

benchmarks :: Benchmark
benchmarks =
  bgroup
    "Data.DeBruijn.Index"
    [ bench_thin
    , bench_thick
    ]

--------------------------------------------------------------------------------
-- Benchmark: thin
--------------------------------------------------------------------------------

bench_thin :: Benchmark
bench_thin = bgroup "thin" (bench_thinWith <$> bench_thinArgs)

bench_thinWith :: (SNatRep, IxRep, IxRep) -> Benchmark
bench_thinWith (nRaw, iRaw, jRaw)
  | let !benchLabel = printf "[%d,%d]" iRaw jRaw :: String
  , SomeIx sn i <- force (toSomeIxRaw (nRaw + 1, iRaw))
  , SomeIx n j <- force (toSomeIxRaw (nRaw, jRaw))
  , Just Refl <- decSNat sn (S n) =
      bench benchLabel $ nf (thin i) j
  | otherwise = error (printf "bench_thinWith(%d,%d,%d): could not construct benchmark" nRaw iRaw jRaw)

bench_thinArgs :: [(SNatRep, IxRep, IxRep)]
bench_thinArgs = nub (evenSpreadBy5 <> alongTheDiagonal)
 where
  evenSpreadBy5 =
    [ (101, i, j)
    | i <- [0, 5 .. 100]
    , j <- [0, 5 .. 100]
    ]
  alongTheDiagonal =
    [ (101, i, i)
    | i <- [0 .. 100]
    ]

--------------------------------------------------------------------------------
-- Benchmark: thick
--------------------------------------------------------------------------------

bench_thick :: Benchmark
bench_thick = bgroup "thick" (bench_thickWith <$> bench_thickArgs)

bench_thickWith :: (SNatRep, IxRep, IxRep) -> Benchmark
bench_thickWith (nRaw, iRaw, jRaw)
  | let !benchLabel = printf "[%d,%d]" iRaw jRaw :: String
  , SomeIx (S n) i <- force (toSomeIxRaw (nRaw, iRaw))
  , SomeIx (S n') j <- force (toSomeIxRaw (nRaw, jRaw))
  , Just Refl <- decSNat n n' =
      bench benchLabel $ nf (thick i) j
  | otherwise = error (printf "bench_thickWith(%d,%d,%d): could not construct benchmark" nRaw iRaw jRaw)

bench_thickArgs :: [(SNatRep, IxRep, IxRep)]
bench_thickArgs = nub (evenSpreadBy5 <> alongTheDiagonal)
 where
  evenSpreadBy5 =
    [ (101, i, j)
    | i <- [0, 5 .. 100]
    , j <- [0, 5 .. 100]
    ]
  alongTheDiagonal =
    [ (101, i, i)
    | i <- [0 .. 100]
    ]
