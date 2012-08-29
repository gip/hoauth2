{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE FlexibleContexts #-}

-- | A simple http client for request OAuth2 tokens and several utils.

module Network.OAuth2.HTTP.HttpClient where

import Control.Applicative ((<$>))
import Control.Exception
import Data.Aeson
import Network.HTTP.Conduit
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy.Char8 as BSL
import qualified Network.HTTP.Types as HT
import Control.Monad.Trans (liftIO)
import Control.Monad.IO.Class (MonadIO)
import Network.HTTP.Types (renderSimpleQuery)
import qualified Data.Text as T
import qualified Data.Text.Encoding as T

import Network.OAuth2.OAuth2

--------------------------------------------------

-- | Request (POST method) access token URL in order to get @AccessToken@.
-- 
--   FIXME: what if @requestAccessToken'@ return error?
--
requestAccessToken :: OAuth2                 -- ^ OAuth Data
                   -> BS.ByteString          -- ^ Authentication code gained after authorization
                   -> IO (Maybe AccessToken) -- ^ Access Token
requestAccessToken oa code = do
  putStrLn "Debug: request Access token 33"
  decode <$> postRequest (accessTokenUrl oa code)


-- | Request the "Refresh Token".
-- 
refreshAccessToken :: OAuth2 
                   -> BS.ByteString    -- ^ refresh token gained after authorization
                   -> IO (Maybe AccessToken)
refreshAccessToken oa rtoken = decode <$> postRequest (refreshAccessTokenUrl oa rtoken)


--------------------------------------------------

-- | Conduct post request in IO monad.
-- 
postRequest :: (URI, PostBody)    -- ^ The URI and request body for fetching token.
             -> IO BSL.ByteString  -- ^ request response
postRequest (uri, body) = doPostRequst (bsToS uri) body 
                          >>= (\ rsp -> do
                                        putStrLn "test"
                                        retOrError rsp)
  where
    retOrError rsp =  if (HT.statusCode . responseStatus) rsp == 200
                      then putStrLn "get response" >> return (responseBody rsp)
                      else throwIO . OAuthException $ "Gaining token failed: " ++ BSL.unpack (responseBody rsp)


--------------------------------------------------
-- od Request Utils
-- TODO: Some duplication here.
-- TODO: Control.Exception.try
--        result <- liftIO $ Control.Exception.try $ runResourceT $ httpLbs request man
-- 
    
-- | Conduct GET request with given URL.
-- 
doSimpleGetRequest :: MonadIO m 
                      => String                       -- ^ URL 
                      -> m (Response BSL.ByteString)  -- ^ Response
doSimpleGetRequest url = liftIO $ withManager $ \man -> do
    req' <- liftIO $ parseUrl url
    httpLbs req' man

-- | Conduct GET request with given URL by append extra parameters provided.
-- 
doGetRequest :: MonadIO m 
                => String                            -- ^ URL
                -> [(BS.ByteString, BS.ByteString)]  -- ^ Extra Parameters
                -> m (Response BSL.ByteString)       -- ^ Response
doGetRequest url pm = liftIO $ withManager $ \man -> do
    req' <- liftIO $ parseUrl $ url ++ bsToS (renderSimpleQuery True pm)
    httpLbs req' man

-- | Conduct POST request with given URL with post body data.
-- 
doPostRequst :: MonadIO m 
                => String                            -- ^ URL
                -> [(BS.ByteString, BS.ByteString)]  -- ^ Data to Post Body 
                -> m (Response BSL.ByteString)       -- ^ Response
doPostRequst url body = liftIO $ withManager $ \man -> do
    req' <- liftIO $ parseUrl url
    liftIO $ putStrLn "doPostRequest start 222"
    liftIO $ print body
--    httpLbs (urlEncodedBody body req') man
    httpLbs req' man

--------------------------------------------------

bsToS ::  BS.ByteString -> String
bsToS = T.unpack . T.decodeUtf8
