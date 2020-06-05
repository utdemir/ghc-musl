module Main (main) where

import Data.Digest.CRC32
import qualified Data.ByteString as BS

main = do
  putStrLn "Hello World!"
  print =<< fmap crc32 BS.getContents
  putStrLn "Done!"

