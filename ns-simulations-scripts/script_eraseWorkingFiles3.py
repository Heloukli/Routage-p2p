#!/usr/bin/env python
# coding: utf-8

########################################################################

#	 Script permettant de supprimer les fichiers temporaire de travail
# créés par le script python 'script_extract1.py'. Car il nécessite des
# fichiers inexistant à chaque nouveau jeu de simulation (vu qu'au cours
# d'un même jeu de simulation il est réappelé à chaque incrémentation
# du paramètre et teste l'existance du fichier pour ajouter le contenu
# calculé à la suite).

########################################################################

import os.path
import sys
import time



# Script Principal
########################################################################

argv = sys.argv
if len(argv) != (2+1):
	print("ERREUR d'arguments")
	print("Devrait être : ' prtcl[str] métrique[str]'.")
	print("argv ["+str(len(sys.argv))+"] = "+str(sys.argv))
	exit(0)
# extraction des arguments
if len(argv) == (2+1):
	prtcl = str(argv[1])
	M = str(argv[2])

# noms des fichiers de trace
fileTrace1 = "outPY_TPP."+prtcl+"."+M+".min.tr"
fileTrace2 = "outPY_TPP."+prtcl+"."+M+".max.tr"
fileTrace3 = "outPY_TPP."+prtcl+"."+M+".avg.tr"

# test l'existance des fichiers, et les supprime au besoin
if os.path.isfile(fileTrace1):
	os.remove(fileTrace1)
if os.path.isfile(fileTrace2):
	os.remove(fileTrace2)
if os.path.isfile(fileTrace3):
	os.remove(fileTrace3)
	
#time.sleep(1)



