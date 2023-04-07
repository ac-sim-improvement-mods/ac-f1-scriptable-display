local overlay = {}

function overlay.drawRaceBorders(borderColor, borderWidth)
	if not car.isInPitlane then
		-- Left Display
		display.rect({
			pos = vec2(2, 525),
			size = vec2(borderWidth, 495),
			color = borderColor,
		})

		-- Right display
		display.rect({
			pos = vec2(1015, 525),
			size = vec2(borderWidth, 495),
			color = borderColor,
		})

		-- Top display
		display.rect({
			pos = vec2(0, 525),
			size = vec2(1020, borderWidth),
			color = borderColor,
		})
	end

	-- Top display
	display.rect({
		pos = vec2(45, 525),
		size = vec2(930, borderWidth),
		color = borderColor,
	})

	-- Left GEAR
	display.rect({
		pos = vec2(414, 782),
		size = vec2(borderWidth, 234),
		color = borderColor,
	})

	-- Right GEAR
	display.rect({
		pos = vec2(603, 782),
		size = vec2(borderWidth, 234),
		color = borderColor,
	})

	-- Below MGUK Delivery
	display.rect({
		pos = vec2(415, 862),
		size = vec2(188, borderWidth),
		color = borderColor,
	})

	-- Below battery level
	display.rect({
		pos = vec2(415, 941),
		size = vec2(188, borderWidth),
		color = borderColor,
	})

	-- -- Lower center cluster left
	-- display.rect({
	-- 	pos = vec2(414, 785),
	-- 	size = vec2(borderWidth, 235),
	-- 	color = borderColor,
	-- })

	-- -- Lower center cluster right
	-- display.rect({
	-- 	pos = vec2(603, 785),
	-- 	size = vec2(borderWidth, 235),
	-- 	color = borderColor,
	-- })

	-- Bottom controls bar
	display.rect({
		pos = vec2(418, 782),
		size = vec2(185, borderWidth),
		color = borderColor,
	})

	-- Left ERS
	display.rect({
		pos = vec2(975, 525),
		size = vec2(borderWidth, 495),
		color = borderColor,
	})

	-- Left ERS
	display.rect({
		pos = vec2(42, 525),
		size = vec2(borderWidth, 495),
		color = borderColor,
	})

	-- Bottom display
	display.rect({
		pos = vec2(360, 1016),
		size = vec2(310, borderWidth),
		color = borderColor,
	})

	-- Bottom display
	display.rect({
		pos = vec2(0, 1016),
		size = vec2(1021, borderWidth),
		color = borderColor,
	})
end

function overlay.drawWarmupBorders(borderColor, borderWidth)
	overlay.drawRaceBorders(borderColor, borderWidth)

	-- Below gear
	display.rect({
		pos = vec2(47, 782),
		size = vec2(929, borderWidth),
		color = borderColor,
	})

	-- Left GEAR
	display.rect({
		pos = vec2(414, 525),
		size = vec2(borderWidth, 257),
		color = borderColor,
	})

	-- Right GEAR
	display.rect({
		pos = vec2(603, 525),
		size = vec2(borderWidth, 257),
		color = borderColor,
	})

	-- Below best lap time
	display.rect({
		pos = vec2(47, 610),
		size = vec2(367, borderWidth),
		color = borderColor,
	})

	-- Below last lap time
	display.rect({
		pos = vec2(608, 610),
		size = vec2(367, borderWidth),
		color = borderColor,
	})

	-- Below left info popups
	display.rect({
		pos = vec2(47, 696),
		size = vec2(367, borderWidth),
		color = borderColor,
	})

	-- Below right info popups
	display.rect({
		pos = vec2(608, 696),
		size = vec2(367, borderWidth),
		color = borderColor,
	})

	-- -- Bottom display
	-- display.rect({
	-- 	pos = vec2(0, 1016),
	-- 	size = vec2(1021, borderWidth),
	-- 	color = borderColor,
	-- })

	-- Left tyres
	display.rect({
		pos = vec2(200, 785),
		size = vec2(borderWidth, 235),
		color = borderColor,
	})

	-- Right tyres
	display.rect({
		pos = vec2(817, 785),
		size = vec2(borderWidth, 235),
		color = borderColor,
	})

	-- Middle left tyres
	display.rect({
		pos = vec2(205, 900),
		size = vec2(209, borderWidth),
		color = borderColor,
	})

	-- Middle right tyres
	display.rect({
		pos = vec2(608, 900),
		size = vec2(209, borderWidth),
		color = borderColor,
	})

	-- Below brakes
	display.rect({
		pos = vec2(47, 862),
		size = vec2(153, borderWidth),
		color = borderColor,
	})

	-- Below tyre compound
	display.rect({
		pos = vec2(47, 941),
		size = vec2(153, borderWidth),
		color = borderColor,
	})

	-- Below fuel level
	display.rect({
		pos = vec2(822, 862),
		size = vec2(153, borderWidth),
		color = borderColor,
	})

	-- Below fuel use
	display.rect({
		pos = vec2(822, 941),
		size = vec2(153, borderWidth),
		color = borderColor,
	})
end

local function drawSharedText()
	local fontSize = 20
	ui.pushDWriteFont("Default;Weight=Black")

	drawText({
		string = "BATT:-",
		fontSize = fontSize,
		xPos = 423,
		yPos = 705,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "MGUH:-",
		fontSize = fontSize,
		xPos = 423,
		yPos = 783,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})

	-- drawText({
	-- 	string = "🔋",
	-- 	fontSize = fontSize + 20,
	-- 	xPos = 417,
	-- 	yPos = 728,
	-- 	xAlign = ui.Alignment.Start,
	-- 	yAlign = ui.Alignment.Center,
	-- })

	-- ui.beginRotation()
	-- if car.kersCharging then
	-- 	drawText({
	-- 		string = "🗲",
	-- 		fontSize = fontSize + 25,
	-- 		xPos = 557,
	-- 		yPos = 725,
	-- 		xAlign = ui.Alignment.Start,
	-- 		yAlign = ui.Alignment.Center,
	-- 	})
	-- end
	-- ui.endRotation(120)

	-- drawText({
	-- 	string = "°C",
	-- 	fontSize = fontSize + 5,
	-- 	xPos = 382,
	-- 	yPos = 710,
	-- 	xAlign = ui.Alignment.Start,
	-- 	yAlign = ui.Alignment.Center,
	-- 	color = rgb.colors.black,
	-- })

	-- drawText({
	-- 	string = "°C",
	-- 	fontSize = fontSize + 5,
	-- 	xPos = 382,
	-- 	yPos = 825,
	-- 	xAlign = ui.Alignment.Start,
	-- 	yAlign = ui.Alignment.Center,
	-- 	color = rgb.colors.black,
	-- })

	-- drawText({
	-- 	string = "°C",
	-- 	fontSize = fontSize + 5,
	-- 	xPos = 615,
	-- 	yPos = 710,
	-- 	xAlign = ui.Alignment.Start,
	-- 	yAlign = ui.Alignment.Center,
	-- 	color = rgb.colors.black,
	-- })

	-- drawText({
	-- 	string = "°C",
	-- 	fontSize = fontSize + 5,
	-- 	xPos = 615,
	-- 	yPos = 825,
	-- 	xAlign = ui.Alignment.Start,
	-- 	yAlign = ui.Alignment.Center,
	-- 	color = rgb.colors.black,
	-- })

	ui.popDWriteFont()
end

function overlay.drawRaceText()
	local fontSize = 20
	drawSharedText()

	ui.pushDWriteFont("Default;Weight=Black")

	drawText({
		string = "BIAS:-",
		fontSize = fontSize + 5,
		xPos = 55,
		yPos = 545,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "DELTA:-",
		fontSize = fontSize + 5,
		xPos = 55,
		yPos = 650,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "GAP:-",
		fontSize = fontSize + 5,
		xPos = 55,
		yPos = 755,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "FUEL:-",
		fontSize = fontSize + 5,
		xPos = 615,
		yPos = 545,
		xAlign = ui.Alignment.End,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "LL:-",
		fontSize = fontSize + 5,
		xPos = 615,
		yPos = 650,
		xAlign = ui.Alignment.End,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "TAR:-",
		fontSize = fontSize + 5,
		xPos = 615,
		yPos = 755,
		xAlign = ui.Alignment.End,
		yAlign = ui.Alignment.Center,
	})

	ui.popDWriteFont()
end

function overlay.drawWarmupText()
	local fontSize = 20
	drawSharedText()

	ui.pushDWriteFont("Default;Weight=Black")

	-- drawText({
	-- 	string = "PSI",
	-- 	fontSize = fontSize,
	-- 	xPos = 275,
	-- 	yPos = 710,
	-- 	xAlign = ui.Alignment.Start,
	-- 	yAlign = ui.Alignment.Center,
	-- 	color = rgb.colors.white,
	-- })

	-- drawText({
	-- 	string = "PSI",
	-- 	fontSize = fontSize,
	-- 	xPos = 275,
	-- 	yPos = 825,
	-- 	xAlign = ui.Alignment.Start,
	-- 	yAlign = ui.Alignment.Center,
	-- 	color = rgb.colors.white,
	-- })

	-- drawText({
	-- 	string = "PSI",
	-- 	fontSize = fontSize,
	-- 	xPos = 720,
	-- 	yPos = 710,
	-- 	xAlign = ui.Alignment.Start,
	-- 	yAlign = ui.Alignment.Center,
	-- 	color = rgb.colors.white,
	-- })

	-- drawText({
	-- 	string = "PSI",
	-- 	fontSize = fontSize,
	-- 	xPos = 720,
	-- 	yPos = 825,
	-- 	xAlign = ui.Alignment.Start,
	-- 	yAlign = ui.Alignment.Center,
	-- 	color = rgb.colors.white,
	-- })

	ui.pushDWriteFont("Default;Weight=Black")

	drawText({
		string = "FUEL:-",
		fontSize = fontSize,
		xPos = 825,
		yPos = 625,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "LL:-",
		fontSize = fontSize,
		xPos = 825,
		yPos = 705,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "FPL:-",
		fontSize = fontSize,
		xPos = 825,
		yPos = 783,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "BIAS",
		fontSize = fontSize,
		xPos = 83,
		yPos = 538,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "EB",
		fontSize = fontSize,
		xPos = 219,
		yPos = 538,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "TORQ",
		fontSize = fontSize,
		xPos = 324,
		yPos = 538,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "ENTRY",
		fontSize = fontSize,
		xPos = 355,
		yPos = 538,
		xAlign = ui.Alignment.End,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "MID",
		fontSize = fontSize,
		xPos = 460,
		yPos = 538,
		xAlign = ui.Alignment.End,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "EXIT",
		fontSize = fontSize,
		xPos = 586,
		yPos = 538,
		xAlign = ui.Alignment.End,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "BEST:-",
		fontSize = fontSize + 5,
		xPos = 52,
		yPos = 415,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})

	drawText({
		string = "-:LAST",
		fontSize = fontSize + 5,
		xPos = 888,
		yPos = 415,
		xAlign = ui.Alignment.Start,
		yAlign = ui.Alignment.Center,
	})

	ui.popDWriteFont()
end

function overlay.drawDisplayOverlay(size, color)
	display.rect({
		pos = vec2(0, 0),
		size = size,
		color = color,
	})
end

return overlay
