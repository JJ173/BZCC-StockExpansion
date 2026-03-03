-- Fix for finding files outside of this script directory.
assert(load(assert(LoadFile("_requirefix.lua")), "_requirefix.lua"))()

-- Required Globals.
require("_GlobalVariables")

-- Required helper functions.
require("_HelperFunctions")

-- Required Skins Logic.
require("_Skins")

-- Database.
local _BZCCDatabase = require("_BZCCDatabase")

-- Subtitles.
local _Subtitles = require('_Subtitles')

-- Managers
local _AnimalManager = require("_AnimalManager")
local _CarrierManager = require("_CarrierManager")
local _CPUManager = require("_CPUManager")
local _SaveLoad = require("_SaveLoad")
local _VoiceManager = require('_VoiceManager')

local _Session = {
    m_GameTPS = GetTPS()
}