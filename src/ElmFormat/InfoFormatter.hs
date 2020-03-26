module ElmFormat.InfoFormatter
    ( InfoFormatter, InfoFormatterF(..), onInfo, approve
    , ExecuteMode(..), init, done, step
    ) where

import Prelude hiding (init)

import Control.Monad.Free
import Control.Monad.State
import ElmVersion (ElmVersion)
import qualified ElmFormat.Version
import ElmFormat.World (World)
import qualified ElmFormat.World as World
import Messages.Strings (showPromptMessage, showInfoMessage)
import Messages.Types
import qualified Text.JSON as Json


class Functor f => InfoFormatter f where
    onInfo :: InfoMessage -> f ()
    approve :: PromptMessage -> f Bool


data InfoFormatterF a
    = OnInfo InfoMessage a
    | Approve PromptMessage (Bool -> a)
    deriving (Functor)


instance InfoFormatter InfoFormatterF where
    onInfo info = OnInfo info ()
    approve prompt = Approve prompt id


instance InfoFormatter f => InfoFormatter (Free f) where
    onInfo info = liftF (onInfo info)
    approve prompt = liftF (approve prompt)


data ExecuteMode
    = ForMachine ElmVersion
    | ForHuman { _usingStdout :: Bool }


init :: World m => ExecuteMode -> (m (), Bool)
init (ForMachine _) = (World.putStr "[", False)
init (ForHuman _) = (return (), undefined)


done :: World m => ExecuteMode -> Bool -> m ()
done (ForMachine _) _ = World.putStrLn "]"
done (ForHuman _) _ = return ()


step :: World m => ExecuteMode -> Bool -> InfoFormatterF a -> StateT Bool m a
step (ForMachine elmVersion) autoYes infoFormatter =
    case infoFormatter of
        OnInfo info next ->
            let
                log =
                    case info of
                        ProcessingFile _ -> return ()
                        FileWouldChange file ->
                            json file
                                ( "File is not formatted with elm-format-" ++ ElmFormat.Version.asString
                                    ++ " --elm-version=" ++ show elmVersion
                                )
                        ParseError inputFile _ _ ->
                            json inputFile "Error parsing the file"
            in
            log *> return next

        Approve _prompt next ->
            case autoYes of
                True -> return (next True)
                False -> return (next False)
step (ForHuman usingStdout) autoYes infoFormatter =
    let
        putStrLn =
            -- we log to stdout unless it is being used for file output (in that case, we log to stderr)
            case usingStdout of
                True -> World.putStrLnStderr
                False -> World.putStrLn
    in
    case infoFormatter of
        OnInfo info next ->
            let
                log =
                    lift $ putStrLn (showInfoMessage info)
            in
            log *> return next

        Approve prompt next ->
            lift $
            case autoYes of
                True -> return (next True)
                False ->
                    putStrLn (showPromptMessage prompt)
                        *> fmap next yesOrNo


json :: World m => FilePath -> String -> StateT Bool m ()
json file message =
    do
        printComma <- get
        when printComma (lift $ World.putStr ",")
        lift $ World.putStrLn $ Json.encode $ Json.makeObj
            [ ( "path", Json.JSString $ Json.toJSString file )
            , ( "message", Json.JSString $ Json.toJSString message )
            ]
        put True


yesOrNo :: World m => m Bool
yesOrNo =
  do  World.flushStdout
      input <- World.getLine
      case input of
        "y" -> return True
        "n" -> return False
        _   -> do World.putStr "Must type 'y' for yes or 'n' for no: "
                  yesOrNo
