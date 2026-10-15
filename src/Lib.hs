module Lib where

import qualified Data.ByteString.Lazy as ByteString
import Discord.Interactions hiding (Options)
import qualified Data.Text.IO as TextIO
import qualified Data.Text as Text
import qualified Data.Map as Map
import Control.Monad.Reader
import System.Environment
import Discord.Requests
import Data.Text (Text)
import Data.Map (Map)
import Discord.Types
import Control.Monad
import GHC.Generics
import System.Exit
import Data.Aeson
import Discord

data Model = Model
  { command :: Map Text Command
  , catch   :: Response
  , prefix  :: Text
  }
  deriving ( FromJSON
           , Generic
           , ToJSON
           , Show
           )

data Command = Command
  { response :: Response
  }
  deriving ( FromJSON
           , Generic
           , ToJSON
           , Show
           )

data Response
  = ResponseText  { text  :: Text }
  | ResponseEmbed { embed :: MyEmbed }
  deriving ( FromJSON
           , Generic
           , ToJSON
           , Show
           )

data MyEmbedImage
  = MyEmbedImageUrl { imageUrl :: Text }
  deriving ( FromJSON
           , Generic
           , ToJSON
           , Show
           )

toCreateEmbedImage :: MyEmbedImage -> CreateEmbedImage
toCreateEmbedImage MyEmbedImageUrl { .. } = CreateEmbedImageUrl imageUrl

data MyEmbedField = MyEmbedField
  { name   :: Text
  , value  :: Text
  , inline :: Maybe Bool
  }
  deriving ( FromJSON
           , Generic
           , ToJSON
           , Show
           )

toEmbedField :: MyEmbedField -> EmbedField
toEmbedField MyEmbedField { .. } = EmbedField
  { embedFieldName   = name
  , embedFieldValue  = value
  , embedFieldInline = inline
  }

data MyEmbed = MyEmbed
  { authorName  :: Text
  , authorUrl   :: Text
  , authorIcon  :: Maybe MyEmbedImage
  , title       :: Text
  , url         :: Text
  , thumbnail   :: Maybe MyEmbedImage
  , description :: Text
  , fields      :: [MyEmbedField]
  , image       :: Maybe MyEmbedImage
  , footerText  :: Text
  , footerIcon  :: Maybe MyEmbedImage
  , color       :: Maybe DiscordColor
  , timestamp   :: Maybe UTCTime
  }
  deriving ( FromJSON
           , Generic
           , ToJSON
           , Show
           )

toCreateEmbed :: MyEmbed -> CreateEmbed
toCreateEmbed MyEmbed { .. } = CreateEmbed
  { createEmbedAuthorName  = authorName
  , createEmbedAuthorUrl   = authorUrl
  , createEmbedAuthorIcon  = toCreateEmbedImage <$> authorIcon
  , createEmbedTitle       = title
  , createEmbedUrl         = url
  , createEmbedThumbnail   = toCreateEmbedImage <$> thumbnail
  , createEmbedDescription = description
  , createEmbedFields      = toEmbedField <$> fields
  , createEmbedImage       = toCreateEmbedImage <$> image
  , createEmbedFooterText  = footerText
  , createEmbedFooterIcon  = toCreateEmbedImage <$> footerIcon
  , createEmbedColor       = color
  , createEmbedTimestamp   = timestamp
  }

getModelFromObj :: IO Model
getModelFromObj = do
  fs <- ByteString.readFile "obj.json"

  case eitherDecode @Model fs of
    Left err -> do
      putStrLn $ "An error occurred parsing the object: " <> err
      exitFailure

    Right mod -> pure mod

toMessageDetailedOpts :: Response -> MessageDetailedOpts
toMessageDetailedOpts (ResponseText  { .. }) = def { messageDetailedContent = text }
toMessageDetailedOpts (ResponseEmbed { .. }) = def { messageDetailedEmbeds = Just [toCreateEmbed embed] }

handler :: Model -> Event -> DiscordHandler ()
handler m (MessageCreate (msg@Message { .. }))
  | Just a <- Text.stripPrefix (prefix m) messageContent = f $ Map.lookup (Text.strip a) (command m)
  | otherwise                                            = pure ()
  where
    g          = CreateMessageDetailed messageChannelId . toMessageDetailedOpts

    f Nothing  = void $ restCall $ g (catch m)
    f (Just x) = void $ restCall $ g (response x)

discordOpts :: Text -> Model -> RunDiscordOpts
discordOpts token m@(Model { .. }) = def 
  { discordToken   = token
  , discordOnStart = pure ()
  , discordOnEvent = handler m
  }

main :: IO ()
main = do
  token <- Text.pack <$> getEnv "TOKEN"
  model <- getModelFromObj
  let opts = discordOpts token model
  TextIO.putStrLn =<< runDiscord opts
