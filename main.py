#ACL - Another Cubzh Loader
import os, time, subprocess, json, io, shutil, sys, psutil
from pathlib import Path

def inject_code(original_file, script_data, line):
	original_data = io.open(str(ResourcesPath)+f"\\bundle\\scripts\\{original_file}", mode="r", encoding="utf-8")
	original_content = original_data.readlines()
	new_content = ""
	for linei in range(len(original_content)):
		new_content += original_content[linei]
		if linei == line:
			for script_line in script_data:
				new_content += script_line
			new_content += "\n"

	original_file = io.open(str(ResourcesPath)+f"\\bundle\\scripts\\{original_file}", mode="w", encoding="utf-8")
	original_file.write(new_content)

if len(sys.argv) == 1:
	print("No launch args. Use --start or --mods")
	sys.exit()

try:
	from colorama import init, Fore, Back, Style
	init()
	pref = f"{Fore.LIGHTBLUE_EX}[ACL]{Fore.WHITE}"
except:
	print("Colorama not installed, skipping..")
	pref = f"[ACL]"

print("ACL starting...")

ResourcesPath = Path(f"C:\\Users\\{os.getlogin()}\\AppData\\Roaming\\Voxowl\\Particubes")
GameCommand = '"C:\\Program Files (x86)\\Steam\\steamapps\\common\\Cubzh\\Cubzh.exe"'
ModsPath = Path(f"Mods\\")

if "--mods" in sys.argv:
	files = os.walk(ModsPath)
	mods = []
	for file in files:
		if file[0] != "Mods":
			if "mod.json" in file[2]:
				try:
					jsonf = io.open(file[0]+"\\mod.json", mode="r", encoding="utf-8")
					content = ""
					for line in jsonf:
						content += line
					props = json.loads(content)
					if props['Name'] == "":
						raise ValueError('Name is empty')
					if props['Author'] == "":
						raise ValueError('Author is empty')
					if props['Version'] == "":
						raise ValueError('Version is empty')
					if props['Priority'] == "":
						raise ValueError('Priority is empty')
					add = True
					notadd = ""
					for mod in mods:
						if mod[3]['Name'] == props['Name']:
							if int(mod[3]['Version'].replace(".", "").replace("v", "").replace(" ", "")) >= int(props['Version'].replace(".", "").replace("v", "").replace(" ", "")):
								add = False
					if add:
						filea = (file[0], file[1], file[2], props)
						mods.append(filea)
						print(f"{pref} {props['Name']} {props['Version']}")
				except Exception as err:
					pass
			else:
				for mod in mods:
					if mod[0].replace(str(ModsPath), "") not in file[0]:
						continue
					else:
						break

	if len(mods) == 0:
		print(f"{pref} Mods not found")

	sys.exit()

if "--start" in sys.argv:
	LaunchArgs = ""

	files = os.walk(ModsPath)
	mods = []
	for file in files:
		if file[0] != "Mods":
			if "mod.json" in file[2]:
				try:
					jsonf = io.open(file[0]+"\\mod.json", mode="r", encoding="utf-8")
					content = ""
					for line in jsonf:
						content += line
					props = json.loads(content)
					if props['Name'] == "":
						raise ValueError('Name is empty')
					if props['Author'] == "":
						raise ValueError('Author is empty')
					if props['Version'] == "":
						raise ValueError('Version is empty')
					if props['Priority'] == "":
						raise ValueError('Priority is empty')
					add = True
					notadd = ""
					for mod in mods:
						if mod[3]['Name'] == props['Name']:
							if int(mod[3]['Version'].replace(".", "").replace("v", "").replace(" ", "")) >= int(props['Version'].replace(".", "").replace("v", "").replace(" ", "")):
								add = False
								notadd = "Same mod, but newer or equal version finded"
					if add:
						filea = (file[0], file[1], file[2], props)
						mods.append(filea)
						print(f"{pref} {props['Name']} {props['Version']} added to loading queue")
					else:
						print(f"{pref} Mod {props['Name']} {props['Version']} will not be loaded. {notadd}")
				except Exception as err:
					print(f"{pref} Mod {file[0].replace('Mods', '')[1:]} will not be loaded. {err}")
			else:
				throw_err = True
				for mod in mods:
					if mod[0].replace(str(ModsPath), "") not in file[0]:
						continue
					else:
						throw_err = False
						break
				if throw_err == True:
					print(f"{pref} Mod {file[0].replace('Mods', '')[1:]} will not be loaded. Missing mod.json")

	if len(mods) == 0:
		print(f"{pref} Mods not found")

	print(f"{pref} Starting Cubzh..")
	cubzh = subprocess.Popen(GameCommand)
	psutil_cubzh = psutil.Process(cubzh.pid)

	print(f"{pref} Cubzh started!")

	#Adjust it if not working
	time.sleep(1.05)

	psutil_cubzh.suspend()
	time.sleep(0.1)
	print(f"{pref} Game suspended!")

	print(f"{pref} Sorting mods by priority..")

	def mods_sort(elem):
		return elem[3]['Priority']

	try:
		mods.sort(key = mods_sort)
	except Exception as err:
		print(f"{pref} Error when sorting mods. '{err}', continuing without sorting.")

	print(f"{pref} Loading mods..")

	for mod in mods:
		print(f"{pref} Mod {mod[3]['Name']} {mod[3]['Version']} Loading..")
		try:
			if "bundle" in mod[1]:
				path = Path(mod[0]+"\\bundle\\")
				files = os.walk(path)
				for file in files:
					filename = file[0].replace(f"{mod[0]}\\bundle", "")
					if filename != "":
						if "scripts" not in filename:
							if len(file[2]) != 0:
								for moddedfile in file[2]:
									shutil.copy(os.path.abspath(file[0] + "\\" + moddedfile), os.path.join(str(ResourcesPath), file[0].replace(f"{mod[0]}\\", "")))
			if "scripts" in mod[1]:
				path = Path(mod[0]+"\\scripts\\")
				files = os.walk(path)
				for file in files:
					filename = file[0].replace(f"{mod[0]}\\scripts", "")
					if filename == "":
						for script in file[2]:
							if ".lua" in script:
								script_data = io.open(file[0]+f"\\{script}", mode="r", encoding="utf-8")

								if script == "splashscreen.Start.lua":
									inject_code("splashscreen.lua", script_data, 0)
								if script == "splashscreen.ClientStart.lua":
									inject_code("splashscreen.lua", script_data, 534)
								if script == "splashscreen.ClientTick.lua":
									inject_code("splashscreen.lua", script_data, 583)
								elif script == "splashscreen.End.lua":
									inject_code("splashscreen.lua", script_data, 1175)

		except Exception as err:
			print(f"{pref} Error when loading {mod[3]['Name']}. {err}")
		time.sleep(0.05) # Fix some issues

	print(f"{pref} Mods loaded!")
	time.sleep(0.1)
	psutil_cubzh.resume()
	print(f"{pref} Game resumed!")
	print(f"{pref} Done!")