#!/usr/bin/env python
# coding: utf-8

########################################################################

#	 Script permettant de fournir des graphiques résumants les
# simulations effectuées pour chaque métrique, en fusionnant les
# graphes des différents protocoles simulés.
#
#	Prend en paramètre d'entrée :
# + une liste de 1 arguments
#	+ métrique observée (typiquement 'avg' 'min' ou 'max' confer script_extract1.py)
# + 3x3 fichiers XGraph (.tr) doivent être présent dans le dossier courrant
#	+ fichier résultat du script_extract1.py
#	+ fichier au nom correspondant au format "outPY_TPP."+prtcl+"."+métrique+"."+suffix+".tr"
#
# 	Ce script produit 3 graphes en compilant les valeurs lu dans les
# 3x3 graphes d'entrée (3 protocoles x 3 métriques).
# Les graphes produit correspondent aux 3 métriques sauf qu'ils fusionnent
# les courbes des 3 protocoles (en Y1...Y3).
#
# Rq : Il est possible de configurer les couleurs des courbes, ainsi que les
# métriques attendues dans la configuration ci-après.

########################################################################

import os.path
import sys
import time



# Configuration
########################################################################

# protocoles
prtcl1 = "AODV"
prtcl2 = "DSDV"
prtcl3 = "DSR"
prtcl4 = "OLSR"
# couleur des courbes
color1 = "blue"
color2 = "green"
color3 = "red"
color4 = "dark-gray"
# paramètres
M1 = "Node"
M2 = "Packet"
M3 = "Speed"


# Fonctions
########################################################################

# extrait les données des fichiers d'entrées et retourne deux liste contenant les valeurs
def extractTPPFromTrace(prtcl, M, suffix):
	V = []
	X = []
	f = open("outPY_TPP."+str(prtcl)+"."+str(M)+"."+str(suffix)+".tr", "r")

	# on zappe les lignes d'entête
	if f.readable():
		f.readline()
		f.readline()
		# f.readline()
		# f.readline()
	else:
		return None

	# on lit les données
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
			if len(t[0]) > 0:
				X.append( float( t[0] ) )

#	print("X = "+str(X))
#	print("Y = "+str(V))
	f.close()
	return [X, V]

# initilise le fichier de sortie en écrivant l'entête
def f_initTraceHeader(f, M, suffix):
	if f.writable():
		f.write("title_x = "+str(M)+"\n")
		f.write("title_y = TPP "+str(suffix)+" (%)\n")
		f.write("title = TauxPertePaquets "+str(suffix)+"\n")
		f.write("Text 0.1 0.3\n")
		f.write("Bleu: AODV\n")
		f.write("End_Text\n")
		f.write("Text 0.1 0.6\n")
		f.write("Vert: DSDV\n")
		f.write("End_Text\n")
		f.write("Text 0.1 0.9\n")
		f.write("Rouge: DSR\n")
		f.write("End_Text\n")
		f.write("Text 0.1 1.2\n")
		f.write("Gris: OLSR\n")
		f.write("End_Text\n")

# écrit les valeurs données dans le fichier de sortie
def f_writeTrace(f, color, X, V):
	if f.writable():
		f.write("color = "+str(color)+"\n")

	# réécriture du graphe
	for i in range(0, len(X)):
		f.write(""+str(X[i])+" "+str(V[i])+"\n")

# fusionne les graphes pour produire le graphe de sortie pour la métrique donnée
def mergeGraph(M, suffix):
	# noms des fichiers de trace
	fileTrace1 = "outPY_TPP."+str(M)+"."+str(suffix)+".tr"

	# ouverture des fichiers de trace
	f1 = open(fileTrace1, "w")
	f_initTraceHeader(f1, M, suffix)

	# récup des données
	tmp = extractTPPFromTrace("AODV", M, suffix)
	Vx = tmp[0]
	Vaodv = tmp[1]
	Vdsdv = extractTPPFromTrace("DSDV", M, suffix)[1]
	Vdsr = extractTPPFromTrace("DSR", M, suffix)[1]

	# écriture des traces résumés
	if f1.writable():
		f_writeTrace(f1, color1, Vx, Vaodv)
		f1.write("next\n")
		f_writeTrace(f1, color2, Vx, Vdsdv)
		f1.write("next\n")
		f_writeTrace(f1, color3, Vx, Vdsr)

	# fermeture des fichiers de trace
	f1.close()

########################################################################



# Script Principal
########################################################################

suffix = "avg"
argv = sys.argv
if len(argv) != (1+1):
	print("ERREUR d'arguments")
	print("Devrait être : 'suffix(str)'.")
	print("argv ["+str(len(sys.argv))+"] = "+str(sys.argv))
	suffix = "avg"
# extraction des arguments
if len(argv) == (1+1):
	suffix = str(argv[1])

# production des graphes fusionnés pour chaques métriques, et pour le suffix donné
time.sleep(1)
mergeGraph(M1, suffix)
mergeGraph(M2, suffix)
mergeGraph(M3, suffix)
time.sleep(1)



