local LDRP = {}

LDRP.TutorialParts = {}
LDRP.CurrentPart = 1
function LDRP.AddTutorial(name,description,pos,angles)
	local New = #LDRP.TutorialParts+1
	LDRP.TutorialParts[New] = {}
	LDRP.TutorialParts[New].name = name
	LDRP.TutorialParts[New].descrpt = description
	LDRP.TutorialParts[New].pos = pos
	LDRP.TutorialParts[New].angs = angles
end
LDRP.AddTutorial("Welcome to L.I.F.E. Roleplay!","Thanks for testing our server!",Vector(-2778,-853,69),Angle(16,-37,0))
LDRP.AddTutorial("Money Printing","You can buy a money printer from the F4 menu and upgrade it by looking at it and typing /upgrade. You can put a cooler on it to prevent it from exploding four times. Printers can hold up to $1500.",Vector(-2771,-5017,122),Angle(14,-57,0))
LDRP.AddTutorial("Thievery","Lockpick and Hacking levels allow faster lockpicking/keypad cracking. You can gain EXP by cracking other player's keypad/fading doors or lockpicking doors.",Vector(-778,-5952,-101),Angle(6,120,0))
LDRP.AddTutorial("Paychecks","This is where you pick your paycheck up. Paychecks come every 15 minutes, so stop by when it's available",Vector(-1396,-840,100),Angle(30,37,0))
LDRP.AddTutorial("Growing Plants","This is the general store - he will sell you ammo for your guns and seeds. Nurturing plants allows you to level up your growing to grow other plants. The pot is located in the F4 shop.",Vector(-2103,-1296,-33),Angle(33,-151,0))
LDRP.AddTutorial("The Drug Dealer","As a drug dealer (job) you can buy weed seeds from here and grow weed - if you have level 2 growing.",Vector(-750,735,-55),Angle(29,72,0))
LDRP.AddTutorial("Bail out of jail","If you happen to get out of the jail, you can talk to the Bail NPC to pay your way out of jail instantly! No hax!",Vector(-2108,196,-123),Angle(1,-57,0))
LDRP.AddTutorial("Mining","Buy a pick from this NPC. Rocks are found around the map (they spawn randomly)",Vector(-1585,-908,-76),Angle(22,88,0))
LDRP.AddTutorial("Crafting","Buy a hammer from this NPC. Hit the crafting table to the left of him with it.",Vector(-1585,-908,-76),Angle(22,88,0))
LDRP.AddTutorial("Inventory System","One main difference with our server vs. traditional DarkRP is when you pickup/purchase certain items/guns, you'll have to hit F4 and check the inventory tab to equip/drop items!",Vector(-2771,-5017,122),Angle(14,-57,0))
LDRP.AddTutorial("Repeating the Tutorial","If you ever want to repeat this tutorial, talk to this woman. She'll bad glad to repeat the tutorial for you!",Vector(-1678,-1528,-51),Angle(25,-50,0))


function LDRP.CreateNewTut(ply,cmd,args)
	if !ply:IsAdmin() then return end
	local Pos = ply:GetPos()
	local Angs = ply:EyeAngles()
	local TutString = [[LDRP.AddTutorial("]] .. args[1] .. [[","]] .. args[2] .. [[",Vector(]] .. math.Round(Pos.x) .. "," .. math.Round(Pos.y) .. "," .. math.Round(Pos.z) .. [[),Angle(]] .. math.Round(Angs.p) .. "," .. math.Round(Angs.y) .. "," .. math.Round(Angs.r) .. [[))]]
	MsgN(TutString)
	SetClipboardText(TutString)
end
concommand.Add("tutorialcreate",LDRP.CreateNewTut)

function LDRP.DoTutorial()
	LDRP.CurrentPart = 1
	if LocalPlayer().InTut then return end
	LocalPlayer().InTut = true
	gui.EnableScreenClicker(true)
	timer.Simple(3,function()
		if !LocalPlayer().InTut then return end
		gui.EnableScreenClicker(true)
	end)
	local NextButton = vgui.Create("DButton")
	NextButton:SetPos(ScrW()-ScrH()*.07-10,ScrH()*.82)
	NextButton:SetSize(ScrH()*.07,ScrH()*.07)
	NextButton:SetText("")
	local CurColor = Color(50,50,50,150)
	NextButton.OnCursorEntered = function()
		CurColor = Color(150,150,150,150)
	end
	NextButton.OnCursorExited = function()
		CurColor = Color(50,50,50,150)
	end
	local w,h = NextButton:GetWide(),NextButton:GetTall()
	NextButton.Paint = function()
		draw.RoundedBox(8,0,0,w,h,CurColor)
		draw.SimpleTextOutlined( ">","Trebuchet24", w*.5, h*.5, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0,255) )
	end
	
	local BackButton = vgui.Create("DButton")
	BackButton:SetPos(10,ScrH()*.82)
	BackButton:SetSize(ScrH()*.07,ScrH()*.07)
	BackButton:SetText("")
	local CurColor = Color(50,50,50,150)
	BackButton.OnCursorEntered = function()
		CurColor = Color(150,150,150,150)
	end
	BackButton.OnCursorExited = function()
		CurColor = Color(50,50,50,150)
	end
	w,h = BackButton:GetWide(),BackButton:GetTall()
	BackButton.Paint = function()
		draw.RoundedBox(8,0,0,w,h,CurColor)
		draw.SimpleTextOutlined( "<","Trebuchet24", w*.5, h*.5, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0,255) )
	end
	BackButton.DoClick = function()
		if LDRP.CurrentPart == 1 then LocalPlayer():ChatPrint("You are already at the start of the tutorial!") return end
		LDRP.CurrentPart = LDRP.CurrentPart-1
		Change = CurTime()
	end
	
	local HasP
	local Change = CurTime()
	NextButton.DoClick = function()
		if !HasP then HasP = true end
		LDRP.CurrentPart = LDRP.CurrentPart+1
		Change = CurTime()
	end

	function LDRP.TutorialHUD()
		if LDRP.CurrentPart <= #LDRP.TutorialParts then
			draw.RoundedBox(0,0,0,ScrW(),ScrH()*.1,Color(0,0,0,180))
			draw.SimpleTextOutlined( LDRP.TutorialParts[LDRP.CurrentPart].name,"HUDNumber", ScrW()*.5, ScrH()*.05, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0,255) )
			
			draw.RoundedBox(0,0,ScrH()*.9,ScrW(),ScrH()*.1,Color(0,0,0,180))
			
			if !HasP then
				draw.SimpleTextOutlined( "Use the arrow buttons on the left and right to go through the tutorial","Trebuchet24", ScrW()*.5, ScrH()*.85, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0,255) )
			end
			
			local D = LDRP.TutorialParts[LDRP.CurrentPart].descrpt
			if string.len(D) < 100 then
				draw.SimpleTextOutlined( D,"Trebuchet24", ScrW()*.5, ScrH()*.95, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0,255) )
			else
				draw.SimpleTextOutlined( string.sub(D,0,100) .. "-","Trebuchet24", ScrW()*.5, ScrH()*.935, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0,255) )
				draw.SimpleTextOutlined( string.sub(D,101,string.len(D)),"Trebuchet24", ScrW()*.5, ScrH()*.97, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0,0,0,255) )
			end
		else
			gui.EnableScreenClicker(false)
			NextButton:Remove()
			BackButton:Remove()
			LocalPlayer().InTut = nil
			RunConsoleCommand("_fintut")
			hook.Remove("CalcView","Sets the view for current tutorial")
			hook.Remove("HUDPaint","The tutorial VGUI")
		end
	end
	hook.Add("HUDPaint","The tutorial VGUI",LDRP.TutorialHUD)

	function LDRP.TutorialView(ply,pos,angles,fov)
		if LDRP.CurrentPart > #LDRP.TutorialParts then return end
		
		local view = {}
		view.origin = LDRP.TutorialParts[LDRP.CurrentPart].pos
		view.angles = LDRP.TutorialParts[LDRP.CurrentPart].angs
		view.fov = fov-math.Clamp(2*(CurTime()-Change),0,20)

		return view
	end
	hook.Add("CalcView","Sets the view for current tutorial",LDRP.TutorialView)
end

function LDRP.StartTut(um)
	LDRP.DoTutorial()
end
usermessage.Hook("SendTut",LDRP.StartTut)