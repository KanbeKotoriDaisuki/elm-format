{-# LANGUAGE OverloadedStrings #-}
module Data.Text.ExtraTest (tests) where

import Elm.Utils ((|>))

import Test.Tasty
import Test.Tasty.HUnit
import qualified Data.Text as Text

import Data.Text.Extra


tests :: TestTree
tests =
    testGroup "Data.Text.ExtraTest"
    [ testCase "when there is no span of the given character" $
        longestSpanOf '*' "stars exist only where you believe"
            |> assertEqual "" NoSpan
    , testCase "when the given character is present" $
        longestSpanOf '*' "it's here -> * <-"
            |> assertEqual "" (Span 1)
    , testCase "only counts the longest span" $
        longestSpanOf '*' "it's here -> ** <-, not here: *"
            |> assertEqual "" (Span 2)
    ]
