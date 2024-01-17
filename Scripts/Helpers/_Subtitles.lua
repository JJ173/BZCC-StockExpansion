--[[
	BZCC Subtitles
	Written by AI_Unit
	Version 1.0 14/09/2022
--]]

-- Return this to whatever file calls it.
local _Subtitles = {}

-- Only so we execute the CFG once.
local subtitlesLoaded = false;

-- Check to see if the subtitle panel is visible.
local startSubtitles = false;

-- Chosen subtitle.
local subtitleToUse = nil;

-- Store the playing clip so we can use it when it's finished.
local audioClip = nil;

-- This determines which panel should be loaded for the text.
local largePanel = false;

-- Set the audioClip variable up so we can track when it's finished.
function _Subtitles.AudioWithSubtitles(clip, useLargePanel)
	-- We need this to load subtitles into the List Box.
	subtitleToUse = RemoveWavExtension(clip) .. "_subtitle.txt";

	-- Set this global variable so we can keep track of the clip until it's finished.
	audioClip = AudioMessage(clip);

	-- Whether we need to use a larger box.
	largePanel = useLargePanel;

	-- Mark this as invisible so we can start the subtitles.
	startSubtitles = true;

	-- Just so we are aware that something is playing.
	return audioClip;
end

-- Run every tick to maintain behaviour.
function _Subtitles.Run()
	if (startSubtitles) then
		-- If we haven't loaded the module, load it up.
		if (not subtitlesLoaded) then
			IFace_Exec("bzgame_subtitles.cfg");
			subtitlesLoaded = true;
		end

		-- Active the subtitle panel.
		if (largePanel) then
			IFace_FillListBoxFromText("SubtitlesPanel_Large", subtitleToUse);
			IFace_Activate("SubtitlesPanel_Large");
		else
			IFace_FillListBoxFromText("SubtitlesPanel", subtitleToUse);
			-- IFace_FillListBoxFromText("SubtitlesPanel_Detailed.SubtitlesPanel_Detailed_Text_Background.SubtitlesPanel_Detailed_Text", subtitleToUse);
			IFace_Activate("SubtitlesPanel");
			-- IFace_Activate("SubtitlesPanel_Detailed");
		end

		-- So we only run once.
		startSubtitles = false;
	end

	if (audioClip ~= nil) then
		if (IsAudioMessageDone(audioClip)) then
			IFace_Deactivate("SubtitlesPanel_Large");
			IFace_Deactivate("SubtitlesPanel");
			-- IFace_Deactivate("SubtitlesPanel_Detailed");
		end
	end
end

function RemoveWavExtension(string)
	return string:gsub("%.wav", "");
end

function IFace_FillListBoxFromText(listBox, file)
	-- Clean up the subtitle box for use of the next title.
	IFace_ClearListBox(listBox);

	-- Split our string based on line break.
	local subtitleText = LoadFile(file);

	-- For all lines, add them as a text item to the given list box.
	for s in subtitleText:gmatch("[^\r\n]+") do
		IFace_AddTextItem(listBox, s);
	end
end

return _Subtitles;
