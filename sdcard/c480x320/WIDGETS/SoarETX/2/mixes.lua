---------------------------------------------------------------------------
-- SoarETX F3K configure mixes and battery warning, loadable component   --
--                                                                       --
-- Author:  Jesper Frickmann                                             --
-- Date:    2025-01-20                                                   --
-- Version: 1.2.4                                                        --
--                                                                       --
-- Copyright (C) EdgeTX                                                  --
--                                                                       --
-- License GPLv2: http://www.gnu.org/licenses/gpl-2.0.html               --
--                                                                       --
-- This program is free software; you can redistribute it and/or modify  --
-- it under the terms of the GNU General Public License version 2 as     --
-- published by the Free Software Foundation.                            --
--                                                                       --
-- This program is distributed in the hope that it will be useful        --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of        --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         --
-- GNU General Public License for more details.                          --
---------------------------------------------------------------------------

local widget, soarGlobals =  ...
local libGUI =  soarGlobals.libGUI
local gui    =  nil
local colors =  libGUI.colors
local title =   "Mixes & Battery"
local modelType = ""
local fm = getFlightMode()

-- Screen drawing constants
local LCD_W2 =  LCD_W / 2
local HEADER =  40
local LINE =    32
local HEIGHT =  LINE - 4
local MARGIN =  15
local W1 =      170
local W2 =      LCD_W2 - 2 * MARGIN - W1

local mixes_F3K = {
  {"Aileron " .. CHAR_RIGHT .. " rudder", 2, -100, 100},
  {"Differential", 3, -100, 100},
  {"Brake " .. CHAR_RIGHT .. " elevator", 4, 0, 40},
  {"Snap - flap", 5, 0, 50},
  {"Elevator input", 6, 20, 100},
  {"Aileron input", 7, 20, 100},
  {"Exponential", 8, 20, 100}
}

local mixes_F3K_RE = {
  {"Elevator input", 6, 20, 100},
  {"Exponential", 8, 20, 100}
}

local mixes_F3K_FH = {
  {"Elevator input", 7, 20, 100},
  {"Aileron input", 0, 10, 100},
  {"Aileron " .. CHAR_RIGHT .. " flaps", 1, 0, 100},
  {"Aileron " .. CHAR_RIGHT .. " rudder", 2, 0, 100},
  {"Differential", 3, -100, 100},
  {"Brake " .. CHAR_RIGHT .. " elevator", 4, 0, 40},
  {"Snap - flap", 5, 0, 50},
  {"Camber " .. CHAR_RIGHT .. " aileron", 6, 0, 200},
  {"Exponential", 8, 0, 100}
}

local mixes_FxJ = {
  {"Aileron " .. CHAR_RIGHT .. " Rudder", 2, -100, 100},
  {"Aileron Travel", 0, -100, 100},
  {"Aileron " .. CHAR_RIGHT .. " Flap", 1, -100, 100},
  {"Aileron Differential", 3, -100, 100},
  {"Brake " .. CHAR_RIGHT .. " Elevator", 4, 0, 40},
  {"Snap - flap", 5, 0, 50},
  {"Camber " .. CHAR_RIGHT .." Aileron", 6, 0, 400}
}

local mixes_FXY = {
  {"Aileron " .. CHAR_RIGHT .. " rudder", 2, -100, 100}
}

local mixes = mixes_F3K

-------------------------------- Setup GUI --------------------------------

local function init()
  gui = libGUI.newGUI()
  -- Extract Model Type from parametes
  modelType = widget.options.Type

  if modelType == "F3K" or modelType == "F3K_TRAD" then
    mixes = mixes_F3K
  elseif modelType == "F3K_FH" then
    mixes = mixes_F3K_FH
  elseif modelType == "F3K_RE" then
    mixes = mixes_F3K_RE
  elseif modelType == "F3J" or modelType == "F5J" then
    mixes = mixes_FxJ
  else
    mixes = mixes_FXY
    modelType = "F??"
  end

  function gui.fullScreenRefresh()
    lcd.clear(COLOR_THEME_SECONDARY3)

    -- Top bar
    lcd.drawFilledRectangle(0, 0, LCD_W, HEADER, COLOR_THEME_SECONDARY1)
    lcd.drawText(10, 2, title.." "..modelType, bit32.bor(DBLSIZE, colors.primary2))

    -- Fligh mode
    local fmIdx, fmStr = getFlightMode()
    lcd.drawText(LCD_W - HEADER, HEADER / 2, "FM" .. fmIdx .. ":" .. fmStr, RIGHT + VCENTER + MIDSIZE + colors.primary2)

    -- Line stripes
    for i = 1, 3, 2 do
      lcd.drawFilledRectangle(0, HEADER + LINE * i, LCD_W, LINE, COLOR_THEME_SECONDARY2)
    end

    local bottom = HEADER + 4 * LINE
    lcd.drawLine(LCD_W2, HEADER, LCD_W2, bottom, SOLID, colors.primary1)

    -- Help text
    local txt = "Some variables can be adjusted individually for each flight mode.\n" ..
                "Therefore, select the flight mode for which you want to adjust.\n" ..
                "You can change that behaviour under GLOBAL VARIABLES."
    lcd.drawTextLines(MARGIN, bottom + 25, LCD_W - 2 * MARGIN, LCD_H - bottom, txt, colors.primary1)
  end

  -- Close button
  local buttonClose = gui.custom({ }, LCD_W - 34, 6, 28, 28)

  function buttonClose.draw(focused)
    lcd.drawRectangle(LCD_W - 34, 6, 28, 28, colors.primary2)
    lcd.drawText(LCD_W - 20, 20, "X", CENTER + VCENTER + MIDSIZE + colors.primary2)

    if focused then
      buttonClose.drawFocus()
    end
  end

  function buttonClose.onEvent(event)
    if event == EVT_VIRTUAL_ENTER then
      lcd.exitFullScreen()
    end
  end

  -- Grid for items
  local x, y = MARGIN, HEADER + 2

  local function move()
    if x == MARGIN then
      x = x + LCD_W2
    else
      x = MARGIN
      y = y + LINE
    end
  end

  -- Add label and number element for a GV
  local function addGV(label, gv, min, max)
    gui.label(x, y, W1, HEIGHT, label)

    local function changeGV(delta, number)
      local value = number.value + delta
      value = math.max(value, min)
      value = math.min(value, max)
      model.setGlobalVariable(gv, fm, value)
      return value
    end

    local number = gui.number(x + W1, y, W2, HEIGHT, 0, changeGV, RIGHT)

    function number.update()
      number.value = model.getGlobalVariable(gv, fm)
    end

    move()
  end

  -- ADD GVs
  for i, mix in ipairs(mixes) do
    addGV(mix[1], mix[2], mix[3], mix[4])
  end

  -- Add battery warning
  gui.label(x, y, W1, HEIGHT, "Battery warning level (V)")

  local function changeBattery(delta, bat)
    local value = bat.value + delta
    value = math.max(0, value)
    value = math.min(200, value)
    soarGlobals.setParameter(soarGlobals.batteryParameter, value - 100)
    return value
  end

  local batP = soarGlobals.getParameter(soarGlobals.batteryParameter)
  gui.number(x + W1, y, W2, HEIGHT, batP + 100, changeBattery, RIGHT + PREC1)
end -- init()

function widget.background()
  gui = nil
end -- background()

function widget.refresh(event, touchState)
  if not event then
    gui = nil
    lcd.drawFilledRectangle(6, 6, widget.zone.w - 12, widget.zone.h - 12, colors.focus)
    lcd.drawRectangle(7, 7, widget.zone.w - 14, widget.zone.h - 14, colors.primary2, 1)
    lcd.drawText(widget.zone.w / 2, widget.zone.h / 2, title, CENTER + VCENTER + MIDSIZE + colors.primary2)
    return
  elseif gui == nil then
    init()
    return
  end

  fm = getFlightMode()
  gui.run(event, touchState)
end -- refresh(...)
