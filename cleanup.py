import os
import shutil
inputfolderpath = r'P:\02\NY\Chautauqua_Co_36013C\STUDY__TO90\TECHNICAL\ENG_FLOOD_HAZ_DEV\COASTAL\WAVE_MODELING\CSHORE\CSHORE_Infile_Creater\output'
directories = ['10000001', '10000002', '10000003', '10000004', '10000005']
remove_files = ["OLONGS", "OMESSG", "OSWASH", "OBSUSL", "OXMOME", "OLOVOL", "OROLLE", "OBPROF", "OTIMSE", "OSETUP", "ODOC", "OYVELO", "OCRVOL", "OENERG", "OCROSS", "OYMOME", "OPORUS", "OSWASE", "OPARAM", "OXVELO", "CSHORE_Runup.exe"]
for root, dirs, files in os.walk(inputfolderpath):
    for direct in dirs:
        if direct in directories:
            temp_dir = os.path.join(root, direct)
            for fil in remove_files:
                try:
                    os.remove(os.path.join(temp_dir, fil))
                except:
                    pass
