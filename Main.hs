-- Nario

module Main where

import Multimedia.SDL
import System.IO.Unsafe (unsafeInterleaveIO)
import Control.Concurrent (threadDelay)

--import Control.Exception

import Player
import Field
import Util
import Const
import Font

wndTitle = "NARIO in Haskell"
wndWidth = 256
wndHeight = 224
wndBpp = 32

frameRate = 60

-- 背景色
backColor = 0x2891ff

-- 描画コマンド
type Scr = Surface -> IO ()

-- エントリ
main :: IO ()
main = do
	sdlInit [VIDEO]
	setCaption wndTitle wndTitle
	sur <- setVideoMode wndWidth wndHeight wndBpp [HWSURFACE, DOUBLEBUF, ANYFORMAT]
	do
		strm <- delayedStream (1000000 `div` frameRate) fetch
		scrs <- process $ map snd $ takeWhile notQuit strm
		mapM_ (\scr -> scr sur) scrs
	sdlQuit

	where
		-- 環境のフェッチ
		fetch = do
			quit <- checkSDLEvent
			ks <- getKeyState
			return (quit, ks)
		notQuit = not . fst

-- 遅延ストリーム
-- microsec 秒ごとに func を実行したアクションの結果をリストとして返す
delayedStream :: Int -> IO a -> IO [a]
delayedStream microsec func = unsafeInterleaveIO $ do
	threadDelay microsec
	x <- func
	xs <- delayedStream microsec func
	return $ x:xs

-- SDL のイベントを処理
-- 終了イベントがきたら True を返す
checkSDLEvent = do
	ev <- pollEvent
	case ev of
		Just QuitEvent	-> return True
		Just (KeyboardEvent { kbPress = True, kbKeysym = Keysym { ksSym = ks, ksMod = km } })
			| ks == SDLK_ESCAPE -> return True
			| ks == SDLK_F4 && (KMOD_LALT `elem` km || KMOD_RALT `elem` km) -> return True
		Nothing	-> return False
		_		-> checkSDLEvent

----

-- 状態
data GameState = GameState {
	pl :: Player,
	fld :: Field
	}

-- 開始状態
initialState = do
	fldmap <- loadField stage
	return GameState {
		pl = newPlayer,
		fld = fldmap
		}
	where
		stage = 0

-- キー入力を処理して描画コマンドを返す
process :: [[SDLKey]] -> IO [Scr]
process kss = do
	imgres <- loadImageResource images
	st <- initialState
	let scrs = map (\scr -> scr imgres) $ loop [] st kss
	return $ scrs ++ [(\sur -> do {releaseImageResource imgres})]
	where
		loop :: [SDLKey] -> GameState -> [[SDLKey]] -> [(ImageResource -> Scr)]
		loop _ _ [] = []
		loop bef gs (ks:kss) = scr' : loop ks gs' kss
			where
				(scr', gs') = update kp gs
				kp = keyProc bef ks

-- 更新
update :: KeyProc -> GameState -> (ImageResource -> Scr, GameState)
update kp gs = (render gs', gs')
	where
		gs' = gs { pl = updatePlayer kp (fld gs) (pl gs) }

-- 描画
render :: GameState -> ImageResource -> Scr
render gs imgres sur = do
	fillRect sur Nothing backColor

	let scrx = getScrollPos (pl gs)

	renderField sur imgres scrx (fld gs)
	renderPlayer sur imgres scrx (pl gs)

	renderInfo gs imgres sur

	flipSurface sur
	return ()

-- 情報描画
renderInfo :: GameState -> ImageResource -> Scr
renderInfo gs imgres sur = do
	puts 3 1 "MARIO"
	puts 3 2 "000000"
	puts 11 2 "?*00"
	puts 18 1 "WORLD"
	puts 19 2 "1-1"
	puts 25 1 "TIME"
	puts 26 2 "255"
	where
		puts = fontPut sur fontsur
		fontsur = getImageSurface imgres ImgFont

-- タイトル画面
renderTitle gs imgres sur = do
	blitSurface (getImageSurface imgres ImgTitle) Nothing sur (pt (5*8) (3*8))
	puts 13 14 "@1985 NINTENDO"
	puts 9 17 "> 1 PLAYER GAME"
	puts 9 19 "  2 PLAYER GAME"
	puts 12 22 "TOP- 000000"
	where
		puts = fontPut sur fontsur
		fontsur = getImageSurface imgres ImgFont