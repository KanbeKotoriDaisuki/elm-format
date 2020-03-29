module CommandLine.World where

import Prelude ()
import Relude hiding (getLine, putStr)

import Data.Text (Text)
import qualified Data.Text as Text
import qualified Data.Text.IO
import qualified Data.ByteString.Lazy as Lazy
import qualified System.Directory as Dir
import qualified System.Environment
import qualified System.Exit
import qualified System.IO


data FileType
    = IsFile
    | IsDirectory
    | DoesNotExist


class Monad m => World m where
    readUtf8File :: FilePath -> m Text
    writeUtf8File :: FilePath -> Text -> m ()
    writeUtf8FileNoOverwrite :: FilePath -> Text -> m ()
    writeUtf8FileNoOverwrite path content =
        do
            exists <- doesFileExist path
            case exists of
                True ->
                    error "file exists and was not marked to be overwritten"
                False ->
                    writeUtf8File path content

    doesFileExist :: FilePath -> m Bool
    doesDirectoryExist :: FilePath -> m Bool
    listDirectory :: FilePath -> m [FilePath]
    stat :: FilePath -> m FileType
    stat path =
        do
            isFile <- doesFileExist path
            isDirectory <- doesDirectoryExist path
            return $ case ( isFile, isDirectory ) of
                ( True, _ ) -> IsFile
                ( _, True ) -> IsDirectory
                ( False, False ) -> DoesNotExist

    getProgName :: m Text

    getStdin :: m Text
    getLine :: m Text
    getYesOrNo :: m Bool
    getYesOrNo =
      do  flushStdout
          input <- getLine
          case input of
            "y" -> return True
            "n" -> return False
            _   -> putStr "Must type 'y' for yes or 'n' for no: " *> getYesOrNo
    putStr :: Text -> m ()
    putStrLn :: Text -> m ()
    writeStdout :: Text -> m ()
    flushStdout :: m ()
    putStrStderr :: Text -> m ()
    putStrLnStderr :: Text -> m()

    exitFailure :: m ()
    exitSuccess :: m ()


instance World IO where
    readUtf8File path = decodeUtf8 <$> readFileBS path
    writeUtf8File path content = writeFileBS path $ encodeUtf8 content

    doesFileExist = Dir.doesFileExist
    doesDirectoryExist = Dir.doesDirectoryExist
    listDirectory = Dir.listDirectory

    getProgName = fmap Text.pack System.Environment.getProgName

    getStdin = decodeUtf8 <$> toStrict <$> Lazy.getContents
    getLine = Data.Text.IO.getLine
    putStr = Data.Text.IO.putStr
    putStrLn = Data.Text.IO.putStrLn
    writeStdout content = putBS $ encodeUtf8 content
    flushStdout = System.IO.hFlush stdout
    putStrStderr = Data.Text.IO.hPutStr stderr
    putStrLnStderr = Data.Text.IO.hPutStrLn stderr

    exitFailure = System.Exit.exitFailure
    exitSuccess = System.Exit.exitSuccess
