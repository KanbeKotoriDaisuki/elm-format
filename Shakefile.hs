import Development.Shake
import Development.Shake.Command
import Development.Shake.FilePath
import Development.Shake.Util
import Debug.Trace

main :: IO ()
main = shakeArgs shakeOptions $ do
    Stdout path <- liftIO $ cmd "stack path --local-install-root"
    let stackLocalInstallRoot = takeWhile (/= '\n') path
    let elmFormat = stackLocalInstallRoot </> "bin/elm-format" <.> exe

    want [ "test" ]

    phony "test" $ do
        need
            [ "_build/stack-test.ok"
            , "_build/run-tests.ok"
            , "_build/shellcheck.ok"
            ]

    phony "clean" $ do
        cmd_ "stack clean"
        removeFilesAfter "_build" [ "//*" ]

    --
    -- build
    --

    elmFormat %> \out -> do
        sourceFiles <- getDirectoryFiles ""
            [ "src//*.hs"
            , "parser/src//*.hs"
            , "markdown//*.hs"
            , "Setup.hs"
            , "elm-format.cabal"
            , "stack.yaml"
            ]
        need sourceFiles
        cmd_ "stack build"

    --
    -- Haskell tests
    --

    "_build/stack-test.ok" %> \out -> do
        testFiles <- getDirectoryFiles ""
            [ "tests//*.hs"
            , "tests//*.stdout"
            , "tests//*.stderr"
            -- source files
            , "src//*.hs"
            , "parser/src//*.hs"
            , "markdown//*.hs"
            , "Setup.hs"
            , "elm-format.cabal"
            , "stack.yaml"
            ]
        need testFiles
        cmd_ "stack test"
        writeFile' out ""

    --
    -- integration tests
    --

    "_build/run-tests.ok" %> \out -> do
        let script = "tests/run-tests.sh"
        need [ script, elmFormat ]
        testFiles <- getDirectoryFiles ""
            [ "tests/test-files//*.elm"
            , "tests/test-files//*.json"
            ]
        need testFiles
        cmd_ "bash" script
        writeFile' out ""

    --
    -- shellcheck
    --

    "_build/shellcheck.ok" %> \out -> do
        scriptFiles <- getDirectoryFiles ""
            [ "tests/run-tests.sh"
            , "package/collect_files.sh"
            , "package/mac/build-package.sh"
            , "package/linux/build-package.sh"
            ]
        let oks = ["_build" </> f <.> "shellcheck.ok" | f <- scriptFiles]
        need oks
        writeFile' out ""

    "_build//*.shellcheck.ok" %> \out -> do
        let script = traceShowId $ dropDirectory1 $ dropExtension $ dropExtension out
        need [ script ]
        cmd_ "shellcheck" script
        writeFile' out ""
