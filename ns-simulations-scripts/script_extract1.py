#!/usr/bin/env python
# coding: utf-8

########################################################################

#	 Script permettant de fournir des graphiques résumants les
# simulations effectuées sur une même métrique.
#
#	Prend en paramètre d'entrée :
# + une liste de 3 arguments
#	+ nom du protocole observé
#	+ nom de la métrique observée
#	+ valeur courante de la métrique
# + 3 fichiers XGraph (.tr) doivent être présent dans le dossier courrant
#	+ fichier résultat de la simulation
#	+ fichier au nom correspondant au format "outPY_TPP."+prtcl+".tr"
#
# 	Ce script produit 3 graphes en compilant les valeurs lu dans les
# 3 graphes d'entrée. Les graphes produit correspondent à :
# un point min, au point max, au point moyen lu parmi tous les points
# des graphes d'entrée. Les 3 points calculés sont ajoutés (en Y) aux
# 3 graphes de sortie pour la valeur de la métrique donnée (en X).
#
#	Rq : Ce script doit donc être appelé successivement plusieurs fois
# suite à plusieurs simulation afin de produire un vrai graphe de
# plusieurs points.

########################################################################

import os.path
import sys
import time



# Fonctions
########################################################################


def extractTPPFromTrace(prtcl, M):
	f = open("out_TPP."+prtcl+".tr", "r")

	if f.readable():
		f.readline()
		f.readline()
		f.readline()
		f.readline()
	else:
		return None

	while f.readable():
		line = f.readline()
		if len(line) == 0:
			break
		# print(line)
		t = line.split(sep=' ')
		if len(t) == 2:
			v = t[1][:-1]
			if len(v) > 0:
				V.append( float( v ) )

	# print("V = "+str(V))
	f.close()
	return V


def f_initTraceHeader(f, prtcl, M, color):
	# title_x = temps (s)
	# title_y = TPP globale (%)
	if f.writable():
		f.write("title = TauxPertePaquets "+str(prtcl)+"\n")
		f.write("color = "+str(color)+"\n")


########################################################################



# Script Principal
########################################################################


prtcl = "PRTCL"
M = "qsdf"
vM = 0

argv = sys.argv
if len(argv) != (3+1):
	print("ERREUR d'arguments")
	print("Devrait être : ' prtcl[str] métrique[str] valeurMétrique[float]'.")
	print("argv ["+str(len(sys.argv))+"] = "+str(sys.argv))
	exit(0)
# extraction des arguments
if len(argv) == (3+1):
	prtcl = str(argv[1])
	M = str(argv[2])
	vM = float(argv[3])

# noms des fichiers de trace
fileTrace1 = "outPY_TPP."+prtcl+"."+M+".min.tr"
fileTrace2 = "outPY_TPP."+prtcl+"."+M+".max.tr"
fileTrace3 = "outPY_TPP."+prtcl+"."+M+".avg.tr"

# ouverture des fichiers de trace
if os.path.isfile(fileTrace1):
	f1 = open(fileTrace1, "a")
else:
	f1 = open(fileTrace1, "w")
	f_initTraceHeader(f1, prtcl, M, "light-gray")
if os.path.isfile(fileTrace2):
	f2 = open(fileTrace2, "a")
else:
	f2 = open(fileTrace2, "w")
	f_initTraceHeader(f2, prtcl, M, "dark-gray")
if os.path.isfile(fileTrace3):
	f3 = open(fileTrace3, "a")
else:
	f3 = open(fileTrace3, "w")
	f_initTraceHeader(f3, prtcl, M, "red")

# récup des données
V = []
V = extractTPPFromTrace(prtcl, M)

# calcule des TauxPertePaquets
_min = min(V)
_max = max(V)
_moy = ( sum(V)/len(V) )

t = vM
#print("t = "+str(t)+" ; _min = "+str(_min)+" ; _max = "+str(_max)+" ; _moy = "+str(_moy))


# écriture des traces résumés
s1 = ""+str(t)+" "+str(_min)+"\n"
s2 = ""+str(t)+" "+str(_max)+"\n"
s3 = ""+str(t)+" "+str(_moy)+"\n"
if f1.writable():
	f1.write(s1)
if f2.writable():
	f2.write(s2)
if f3.writable():
	f3.write(s3)

# fermeture des fichiers de trace
f1.close()
f2.close()
f3.close()

time.sleep(1)



