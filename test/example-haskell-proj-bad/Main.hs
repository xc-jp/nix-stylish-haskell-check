module Main where

-- There shouldn't be extra space after the Conduit type in the parenthesis.
-- This will cause stylish-haskell to fail.
import Data.Conduit (Conduit   )

main :: IO ()
main = putStrLn "Hello, Haskell!"
