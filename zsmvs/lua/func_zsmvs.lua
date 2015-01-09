function AddZSMap(name, cleanname, description, author, minplayers)
	table.insert(maplist, {
		["Mapname"] = name,
		["Name"] = cleanname,
		["Desc"] = description,
		["Author"] = author,
		["MinPlayers"] = tonumber(minplayers),
		["Votes"] = tonumber(0),
		["Locked"] = tonumber(0)
	})
end

function CreateFile(files)
	if not file.Exists(files, "DATA") then
		file.Write(files, "")
		MsgN("Created a non-existant data named as ".. files)
	end
end

function DeleteLegacyFiles(files, recent)
	local versioning = file.Find(files, "DATA")
	for k,_ in pairs(versioning) do
		if versioning[k] ~= recent then
			MsgN("Found legacy version of ".. versioning[k] ..", deleting...")
			file.Delete(versioning[k])
		end
	end
end

function DeleteEmptyTable(tables)
	if #tables <= 0 then return {} end

	repeat
		noemptyleft = true
		for k, _ in pairs(tables) do
			if string.len(string.gsub(tables[k], " ", "")) == 0 then
				table.remove(tables, k)
				noemptyleft = false
			end
		end
	until noemptyleft

	return tables
end