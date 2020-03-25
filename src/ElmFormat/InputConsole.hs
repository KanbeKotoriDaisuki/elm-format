module ElmFormat.InputConsole (InputConsole, InputConsoleF(..), readStdin, execute) where

import Control.Monad.Free
import Data.Text (Text)
import ElmFormat.World (World)
import qualified ElmFormat.World as World


class Functor f => InputConsole f where
    readStdin :: f Text


data InputConsoleF a
    = ReadStdin (Text -> a)
    deriving (Functor)


instance InputConsole InputConsoleF where
    readStdin = ReadStdin id


instance InputConsole f => InputConsole (Free f) where
    readStdin = liftF readStdin


execute :: World m => InputConsoleF a -> m a
execute operation =
    case operation of
        ReadStdin next ->
            next <$> World.getStdin
