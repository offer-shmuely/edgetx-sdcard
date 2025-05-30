---- #########################################################################
---- #                                                                       #
---- # Copyright (C) EdgeTX                                                  #
-----#                                                                       #
---- # License GPLv2: http://www.gnu.org/licenses/gpl-2.0.html               #
---- #                                                                       #
---- # This program is free software; you can redistribute it and/or modify  #
---- # it under the terms of the GNU General Public License version 2 as     #
---- # published by the Free Software Foundation.                            #
---- #                                                                       #
---- # This program is distributed in the hope that it will be useful        #
---- # but WITHOUT ANY WARRANTY; without even the implied warranty of        #
---- # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
---- # GNU General Public License for more details.                          #
---- #                                                                       #
---- #########################################################################
local options = {
}

local INDENT = 1 -- left margin in pixels

local function create(zone, options)
  local widget = { zone=zone, options=options }
  return widget
end

local function update(widget, options)
  widget.options = options
end

local function background(widget)
end

function refresh(widget, event, touchState)
  local GPSTable = getTxGPS()
  if GPSTable ~= nil then
    local numsat = GPSTable.numsat

    if numsat ~= nil then
        lcd.drawText(INDENT, 0, "NumSat: " .. string.format("%d", numsat), LEFT + COLOR_THEME_SECONDARY1) -- internal gpsData.numSat
    else
        lcd.drawText(INDENT, 0, "NumSat: no data yet", LEFT + COLOR_THEME_SECONDARY1)
    end

    if GPSTable.fix then
      lcd.drawText(INDENT, 20, "GPS Lock", LEFT + COLOR_THEME_SECONDARY1)
    else
      lcd.drawText(INDENT, 20, "No GPS lock yet", LEFT + COLOR_THEME_SECONDARY1)
    end

    -- if (GPSTable.fix==true) then
    lcd.drawText(INDENT, 40, "HDOP: " .. string.format("%.1f",GPSTable.hdop * 0.01), LEFT + COLOR_THEME_SECONDARY1) -- internal gpsData.hdop
    lcd.drawText(INDENT, 60, "Lat: " .. string.format("%f",GPSTable.lat), LEFT + COLOR_THEME_SECONDARY1) -- internal gpsData.latitude * 0.000001, positive is North
    lcd.drawText(INDENT, 80, "Lon: " .. string.format("%f",GPSTable.lon), LEFT + COLOR_THEME_SECONDARY1) -- internal gpsData.longitude * 0.000001, positive is East
    lcd.drawText(INDENT, 100, "Alt: " .. string.format("%d",GPSTable.alt) .. " m", LEFT + COLOR_THEME_SECONDARY1) -- internal gpsData.altitude (precision 1m)
    lcd.drawText(INDENT, 120, "Spd: " .. string.format("%.2f",GPSTable.speed * 0.01) .. " m/s", LEFT + COLOR_THEME_SECONDARY1) -- internal gpsData.speed in [cm/s]
    lcd.drawText(INDENT, 140, "Head: " .. string.format("%d",GPSTable.heading * 0.1) .. " deg", LEFT + COLOR_THEME_SECONDARY1) -- internal gpsData.groundCourse in 10 deg units
    -- end
  else
    lcd.drawText(INDENT, 0, "No TxGPS detected!", LEFT + COLOR_THEME_SECONDARY1)
    lcd.drawText(INDENT, 40, "Make sure your firmware", LEFT + COLOR_THEME_SECONDARY1)
    lcd.drawText(INDENT, 60, "has GPS support enabled!", LEFT + COLOR_THEME_SECONDARY1)
  end
end

return { name="TxGPStest", options=options, create=create, update=update, refresh=refresh, background=background }
