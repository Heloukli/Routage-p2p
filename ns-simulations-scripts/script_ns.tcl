###########################################################################


#
#	CONFIGURATION
#
###########################################################################


# variables de simulation :
	# nombre de noeud dans le réseau
set CST_NbNode				50				;# constante de simulation
set _NbNodeMin				10				;# min noeuds dans le réseau
set _NbNodeMax				100				;# max noeuds dans le réseau
set _NbNodeInc				10				;# interval des simulations
	# vitesse de déplacement des noeuds
set CST_NodeSpeed			25				;# constante de simulation
set _NodeSpeedMin			5				;# min noeuds dans le réseau
set _NodeSpeedMax			55				;# max noeuds dans le réseau
set _NodeSpeedInc			5				;# interval des simulations
	# nombre de paquet envoyé par communication
set CST_NbPacketSent		1000			;# constante de simulation
set _NbPacketSentMin		200				;# min noeuds dans le réseau
set _NbPacketSentMax		3800			;# max noeuds dans le réseau
set _NbPacketSentInc		400				;# interval des simulations

# configuration modifiable :
	# applications de sorties :
set _VIEW_NAM				0				;# 0/1: lance (ou non) NAM en fin sur la trace .nam générée
set _VIEW_XGRAPH			0				;# 0/1: lance (ou non) XGraph en fin sur les graphes temporaires .tr générés
set _VIEW_XGRAPH_END		0				;# 0/1: lance (ou non) XGraph en fin sur les graphes résultats .tr générés
	# traces NS :
set _WiredRouting			ON				;# génération de la trace NS Wifi
set _AgentTrace 			OFF				;# génération de la trace NS Agent
set _RouterTrace			ON				;# génération de la trace NS Routage
set _MacTrace				OFF				;# génération de la trace NS MAC
	# simulation :
set _SimTimeLapse			100				;# temps max de simulation (sec)
set _SimTrafficStart		5				;# début du traffic (sec)
set _NbConnections			35				;# nombre de connexion entre pair de noeud (devrait être inférieur à NbNode)
	# NAM :
set _NamNodeSize			80				;# taille des noeuds
set _NamDeltaNodeMove		10				;# changement de direction des noeuds tous les X sec de simulation
set _NamSpeed				12.5ms			;# vitesse de lecture de simulation
	# XGraph :
set _RecordLapseTime		1.0				;# delta tps entre les différents enregistrements
	# fichiers de sorties :
set _FILEPATH_XGRAPH		~/Documents/ns-allinone-2.35/bin/xgraph
set _FILEPATH_NS			out_ns
set _FILEPATH_NAM			out_nam
set _FILEPATH_XGRAPH_1		out_TPP			;# Taux de Perte des Paquets (%)

# paramètres :
	# couche routage :
set _RoutingPrtcl			AODV			;# prtcl de routage (AODV, DSDV DSR, [OLSR]) [valeur par défaut modifiée par l'exécution]
	# trafic :
set _AgentType				UDP				;# type d'agent (UDP ou TCP)
set _TraficType				CBR				;# type de traffic				
set _PacketsTransmitionRate	8.0				;# vitesse de transmission (p/s) [valeur par défaut modifiée par l'exécution]
set _PacketsPeakRate		1536Kb			;# vitesse max (bits/s)
set _PacketsSize			512				;# taille des paquets (octets)
	# mobilité
set _NetworkWidth			1000			;# taille X de la topologie
set _NetworkHeigth			1000			;# taille Y de la topologie
set _MobilityModel			RandomWaypoint	;# modèle de mobilité
	# couche physique :
set _CommunicationRange		250m			;# rayon de portée des noeuds (m)
set _Debit					2Mb				;# débit de transfert (Mb, kb, ...)
	# config noeuds :
set _LinkLayer				LL						;# type de couche de liaison
set _MacType            	Mac/802_11				;# type MAC
set _QueueType				Queue/DropTail/PriQueue	;# type d'interface
set _MaxSizeQueue			50						;# nb paquet max en file d'attente
set _AntModel				Antenna/OmniAntenna		;# modèle d'antenne
set _ReflectionModel		Propagation/TwoRayGround;# modèle de reflexion : Two-ray Ground
set _NetworkInterfaceType	Phy/WirelessPhy			;# type d'interface réseau
set _ChannelType			Channel/WirelessChannel	;# type de canal	


###########################################################################





#
#	PROCÉDURES MODIFIABLES
#
###########################################################################


# initialise les entêtes des fichiers trace de sortie
proc sim_initTraceOutput { f1 } {
	# color =
	# black, white, red, blue, green, violet, orange, yellow, pink, cyan, light-gray, dark-gray, fuchsia (default)

	# f1
	puts $f1 "title = Taux Perte Paquets (%)"
	puts $f1 "title_x = temps (s)"
	puts $f1 "title_y = TPP globale (%)"
	puts $f1 "color = blue"
}

# collecte les données au cour de la simulation, les traite, puis les écrit dans les fichiers de sortie
proc sim_record { ns f1 _NbNode } {
	global _RecordLapseTime _NbConnections \
			nodes sinks
	
	set delta $_RecordLapseTime						;# intervale de temps pour l'enregistrement
	set now [$ns now]								;# temps de simulation courant
	set N [expr min($_NbNode, $_NbConnections)]		;# NbConnexion restraint à NbNoeud s'il n'y a pas assez de noeud ou de co
	
	set Tlost 0
	set Trecv 0
	for {set i 0} {$i < $N} {incr i} {
	
		# récupération des données :
#		set b0 [$sinks($i) set bytes_]			;# nb octets reçus
		set b1 [$sinks($i) set nlost_]			;# nb paquets perdus
		set b2 [$sinks($i) set npkts_]			;# nb paquets reçus
#		set b3 [$sinks($i) set lastPktTime_]	;# temps où le dernier paquets est reçu
	
		# save
		set Tlost [expr $Tlost + $b1]
		set Trecv [expr $Trecv + $b2]

		# on reset les variables
		$sinks($i) set bytes_ 0
		$sinks($i) set nlost_ 0
	}
	
	# calcule du Taux de Perte des Paquets (par l'ensemble des noeuds à chaque instant)
	set T [expr $Tlost + $Trecv]

	if { $T > 0 } then {
		set TPP [expr ($Tlost * 100) / $T]
	} else {
		set TPP 0
	}
	
	
	# écriture dans le fichier
	puts $f1 "$now $TPP"
	
	
	# replannification du record à deltaTemps plus tard
	$ns at [expr $now+$delta] "sim_record $ns $f1 $_NbNode"
}

# termine la simulation et exécute des applications externes
proc sim_finish { ns f1 fnstrace fnamtrace _Prtcl } {
	# écriture de la trace de simulation :
	$ns flush-trace
	close $fnstrace 
	close $fnamtrace
	
	# fermeture des fichiers
	close $f1

	# execution d'application externe :
		# visualisation du réseau :
	global _VIEW_NAM _FILEPATH_NAM
	if { $_VIEW_NAM } then {
		exec nam "$_FILEPATH_NAM.$_Prtcl.nam" &
	}
		# visualisation des stats
	global _VIEW_XGRAPH _FILEPATH_XGRAPH _FILEPATH_XGRAPH_1
	if { $_VIEW_XGRAPH } then {
		exec $_FILEPATH_XGRAPH "$_FILEPATH_XGRAPH_1.$_Prtcl.tr" &
	}
	
	# on termine la session de simulation (scheduler)
	$ns halt
}


###########################################################################





#
#	PROCÉDURES FIXES
#
###########################################################################


##		PROCÉDURES DE SIMULATION
###########################################################################


# vérification de configuration et paramétrages de dernière minute
proc sim_init { _Prtcl } {
	global _QueueType _CommunicationRange _Debit
	
	# Exception DSR :
	if { $_Prtcl == "DSR" } then {
		set _QueueType CMUPriQueue
	} else {
		set _QueueType Queue/DropTail/PriQueue
	}
	# Correction pour DSR :
	# 	"erreur de segmentation" dû au type de file d'attente utilisé.

	# Antenne :
		#	RXThresh_ is the reception threshold. If the received signal strength is
		#greater than this threshold, the packet can be successfully received.
		# The receiving power threshold in Watt.
		#	CSThresh_ is the carrier sensing threshold. If received signal strength is
		#greater than this threshold, the packet transmission can be
		#sensed. However, the packet cannot be decoded unless signal strength is
		#greater than RXThresh_.
		# The carrier sense threshold in Watt.
		#	CPThresh_ refers to the capture phenomenon. If two packets are received
		#simultaneously, i.e. they collide, it is still possible to receive the
		#'stronger' packet if its signal strength is CPThresh_ times the other
		#packet. For example, if CPThresh_ is 10.0, the stronger packet in a
		#collision can be decoded if its signal strength is at least 10.0 times
		#that of the other packet; otherwise, both packets are lost in the
		#collision.
		# The capture threshold in Watt.
	if { $_CommunicationRange == "550m" } then {
		Phy/WirelessPhy set RXThresh_ 4.4613e-10	;# 250m
		Phy/WirelessPhy set CSThresh_ 9.21756e-11   ;# 550m
		Phy/WirelessPhy set bandwidth_ $_Debit		;# bande passante
	} else {
		Phy/WirelessPhy set RXThresh_ 1.20174e-13	;# 50m
		Phy/WirelessPhy set CSThresh_ 4.4613e-10	;# 250m
		Phy/WirelessPhy set bandwidth_ $_Debit		;# bande passante
	}

	# MAC :
		#	"All the control packets would be transmitted through the basicRate_ which
		#is mostly 1Mbps, configuration is in the file ns2/tcl/lan/ns-mac.tcl; All
		#the data packet would be transmitted through the dataRate_ which is also
		#mostly 1Mbps; You need to specify it through your tcl configuration
		#simulation  file if you need another value for them, especally a different
		#bandwidth_;"
	Mac/802_11 set basicRate_ $_Debit
	Mac/802_11 set dataRate_ $_Debit
}

# initialise la configuration des noeuds pour la simulation
proc sim_initNodes { ns _Prtcl topology } {
	global _LinkLayer _MacType _QueueType _MaxSizeQueue _AntModel _ReflectionModel  \
			_NetworkInterfaceType _ChannelType _WiredRouting _AgentTrace \
			_RouterTrace _MacTrace
		
	# configuration des noeuds :
	$ns node-config \
		-adhocRouting $_Prtcl \
		-llType $_LinkLayer \
		-macType $_MacType \
		-ifqType $_QueueType \
		-ifqLen $_MaxSizeQueue \
		-antType $_AntModel \
		-propType $_ReflectionModel \
		-phyType $_NetworkInterfaceType \
		-channel [ new $_ChannelType ] \
		-topoInstance $topology \
		-movementTrace $_WiredRouting \
		-agentTrace $_AgentTrace \
		-routerTrace $_RouterTrace \
		-macTrace $_MacTrace
}

# initialise la position des noeuds dans NS et NAM
proc sim_initNodePositions { ns _NbNode } {
	global _NamNodeSize _NetworkWidth _NetworkHeigth _VIEW_NAM \
			nodes

	# positionnement aléatoire des noeuds au commencement
	for {set i 0} { $i < $_NbNode } { incr i } {
		# désactivation de la mobilité des noeuds pour la gérer à la main
		$nodes($i) random-motion 0

		# changement des valeurs au sein des instances des noeuds :
		$nodes($i) set X_ [ expr 5+round(rand() * ($_NetworkWidth-5*2)) ]
		$nodes($i) set Y_ [ expr 5+round(rand() * ($_NetworkHeigth-5*2)) ]
		$nodes($i) set Z_ 0.0
	}
	
	# définie la position initiale des noeuds dans NAM avec une taille donnée
	if {$_VIEW_NAM} then {
		for { set i 0 } { $i < $_NbNode } { incr i } {
			$ns initial_node_pos $nodes($i) $_NamNodeSize
		}
	}
}

# génère et planifie des mouvements aléatoires pour les noeuds au cours de la simulation
proc sim_genNodesMovement { ns _NbNode _NodeSpeed } {
	global _SimTimeLapse _NamDeltaNodeMove _NetworkWidth _NetworkHeigth \
			nodes

	# déplacement aléatoire des noeuds au cours de la simulation :
	for {set i 0} { $i < $_NbNode } { incr i } {
		# j changement de déplacement par noeud
		for {set j 0} { $j < [expr round($_SimTimeLapse/$_NamDeltaNodeMove)] } { incr j } {
			set x [ expr 5+round(rand() * ($_NetworkWidth-2*5)) ]
			set y [ expr 5+round(rand() * ($_NetworkHeigth-2*5)) ]
			# ordres planifiés pour déplacement futur
			$ns at [ expr $_NamDeltaNodeMove*$j ] "$nodes($i) setdest $x $y $_NodeSpeed"
		}
	}
}

# crée et retourne un nouvel objet agent/UDP|TCP
proc sim_createAgent {} {
	global _AgentType
	
	# agent UDP :
	if {$_AgentType == "UDP"} then {
		return [new Agent/UDP]
	# agent TCP
	} elseif {$_AgentType == "TCP"} then {
		return [new Agent/TCP]
	# erreur
	} else {
		error "Le paramètre _AgentType doit valoir 'UDP' ou 'TCP'."
	}
}

# crée et retourne un nouvel objet agent/sink
proc sim_createSink {} {
	return [new Agent/LossMonitor]
}

# crée, paramètre et retourne un nouvel objet traffic
proc sim_createTraffic {} {
	global _PacketsSize _PacketsPeakRate _PacketsTransmitionRate
	
	set traffic [new Application/Traffic/CBR]  
	$traffic set packetSize_ $_PacketsSize						;# The size in bytes to use for all packets from this source.
	$traffic set rate_ $_PacketsPeakRate						;# Peak rate in bits per second.
	$traffic set interval_ [expr 1/$_PacketsTransmitionRate]	;# The amount of time to delay between packet transmission times.
	
	return $traffic
}

# connecte le noeud source j au noeud puits i
proc sim_createConnection { ns i j } {
	global nodes sinks agents traffics
	
	# on attache le puit au noeud1 (destination)
	$ns attach-agent $nodes($i) $sinks($i)
	# on attache l'agent au noeud2 (source)
	$ns attach-agent $nodes($j) $agents($i)
	
	# on attache le trafic à l'agent
	$traffics($i) attach-agent $agents($i)
	
	# on connecte l'agent au puits
	$ns connect $agents($i) $sinks($i)
}

# génère le scénario de traffic entre les noeuds du réseau au cours de la simulation
proc sim_genTrafficScenario { ns _NbNode _NbPacketSent } {
	# mise en place du traffic UDP entre les noeuds du réseau :
	# 	soit N communication entre des pairs de noeuds aléatoirement choisi
	#	tel qu'une communication est une transmission de M de n0(Agent/CBR/UDP/512o) vers n1(Agent/sink)
	
	global nodes agents sinks traffics \
			_NbConnections _AgentType _TraficType \
			_PacketsSize _PacketsPeakRate _PacketsTransmitionRate \
			_SimTrafficStart _SimTimeLapse
	
	# NbConnexion restraint à NbNoeud s'il n'y a pas assez de noeud ou de co
	set N [expr min($_NbNode, $_NbConnections)]
	# calcule et màj du taux de transmission selon le nombre de paquets à envoyer pendant la simulation
	set _PacketsTransmitionRate [expr $_NbPacketSent / ( ($_SimTimeLapse - $_SimTrafficStart)*1.0 )]
	puts "Taux de transmission des paquets : $_PacketsTransmitionRate"
	
	# création des objets
	for {set i 0} {$i < $N} {incr i} {
		# puits
		set sinks($i) [sim_createSink]
		# source
		set agents($i) [sim_createAgent]
		# traffic
		set traffics($i) [sim_createTraffic]
	}
	
	# création des connexions
	puts "Liste des connextions (i: puits, 2:src)"
	puts "---------------------------------------"
	for {set i 0} {$i < $N} {incr i} {
		# id du noeud source (i étant l'id du noeud puits)
		set j [ expr round(rand() * $_NbNode) % $_NbNode ]		;# noeud aléa parmis les noeuds du réseau
		puts "i=$i j=$j"
		
		# connexion du noeud source j au noeud puits i
		sim_createConnection $ns $i $j							;# sim_createConnection { ns i j }
	}
	puts "---------------------------------------"

	# planification du trafic
	for {set i 0} {$i < $N} {incr i} {
		# lancement du début du trafic à SimTimeLapse sec pour tous les noeuds
		$ns at [expr $_SimTrafficStart + (0.1 * $i)] "$traffics($i) start"
		# fin de transfert en fin de simulation
		$ns at [expr $_SimTimeLapse] "$traffics($i) stop"
	}
}

# lance une simulation en fonction des variables de simulation donnée en entrée
proc sim_run { _NbNode _NodeSpeed _NbPacketSent _Prtcl } {
	global _FILEPATH_XGRAPH_1 _FILEPATH_NS _FILEPATH_NAM _VIEW_NAM \
			_SimTimeLapse _NetworkWidth _NetworkHeigth _NamSpeed \
			nodes sinks agents traffics NbSimDone

	# réinitialisation des variables de travail
	array set nodes {}
	array set sinks {}
	array set agents {}
	array set traffics {}
	incr NbSimDone
	
	# pour calcul du temps total de cette simulation
	set TTime [clock clicks -millisec]
	
	# check config
	sim_init $_Prtcl
	
	puts " "
	puts "( $NbSimDone )\t+--> #Node: $_NbNode Speed: $_NodeSpeed #PacketSent $_NbPacketSent Prtcl: $_Prtcl"
	
	# simulateur
	set ns [new Simulator]

	# ouverture des fichiers trace de sortie :
	set f1 [open "$_FILEPATH_XGRAPH_1.$_Prtcl.tr" w]

	# fichier de log
	set fnstrace [open "$_FILEPATH_NS.$_Prtcl.trace" w]
	set fnamtrace [open "$_FILEPATH_NAM.$_Prtcl.nam" w]

	# log
#	$ns use-newtrace							;# permet d'utiliser le nouveau format de trace
	$ns trace-all $fnstrace
	#$ns namtrace-all $fnamtrace
	$ns namtrace-all-wireless $fnamtrace $_NetworkWidth $_NetworkHeigth


	# topologie réseau
	set topology [new Topography]
	$topology load_flatgrid $_NetworkWidth $_NetworkHeigth
	set god [create-god [expr $_NbNode + 10]]			;# God (General Operations Director) is the object that is used to store global information about the state of the environment, network or nodes.
	# Rq : Pourquoi NbNode + 10 ?
	# 	Correction de l'erreur :
	# 	"MAC_802_11: accessing MAC cache_ array out of range"
	# 	Mais sur un grand nombre de simulation successive dans
	#	un même script, le warning réapparait... -_-'


	# init nodes
	sim_initNodes $ns $_Prtcl $topology					;# sim_initNodes {ns _Prtcl topology}

	# récupération des instances des noeuds
	for {set i 0} { $i < $_NbNode } { incr i } {
		set nodes($i) [$ns node]
	}
	
	# init position des noeuds
	sim_initNodePositions $ns $_NbNode					;# sim_initNodePositions { ns _NbNode }


	# planification de déplacement des noeuds
	sim_genNodesMovement $ns $_NbNode $_NodeSpeed		;# sim_genNodesMovement {ns _NbNode _NodeSpeed}

	# génération du traffic entre les noeuds du réseau
	sim_genTrafficScenario $ns $_NbNode $_NbPacketSent	;# sim_genTrafficScenario { ns _NbNode _NbPacketSent }


	# Scénario de simulation général :
		# lancement des init pour les traces
	$ns at 0.0 "sim_initTraceOutput $f1"
		# vitesse de simulation dans NAM
	$ns at 0.0 "$ns set-animation-rate $_NamSpeed"
		# lancement des récupérations de donnée dès le début
	$ns at 0.1 "sim_record $ns $f1 $_NbNode"		;# /!\ 0.1 sinon conflis avec sim_initTraceOutput
		# couleur rouge du noeud puit (n: 0)
	$nodes(0) color red
	$ns at 0.0 "$nodes(0) color red"
		# notifie aux noeuds la fin de simulation
	for { set i 0 } { $i < $_NbNode } { incr i } {
		$ns at [expr $_SimTimeLapse] "$nodes($i) reset";
	}
		# déclanchement de la procédure de fin de simulation
	$ns at [expr $_SimTimeLapse+0.1] "$ns nam-end-wireless $_SimTimeLapse"
	$ns at [expr $_SimTimeLapse+0.1] "sim_finish $ns $f1 $fnstrace $fnamtrace $_Prtcl"
	# Rq : Il faut tenir compte aussi des déclanchement des flux de
	# donnée UDP/CBR déclanchés plus haut par la génération de traffic.
	# Ainsi que les déplacements planifiés des noeuds pour la mobilité.
	

	# lancement de la simulation
	$ns run
	
	# on détruit le simulateur
	$ns destroy
	
	# affichage du temps total pour cette simulation
	set TTime [expr { ( [clock clicks -millisec] - $TTime )/1000.0 }]
	puts stderr "Temps de simulation ( $NbSimDone ) : $TTime sec"
	puts "( $NbSimDone )\t+--> #Node: $_NbNode Speed: $_NodeSpeed #PacketSent $_NbPacketSent Prtcl: $_Prtcl"
}


###########################################################################


##		PROCÉDURES PRINCIPALES
###########################################################################



# lance les simulations pour la métrique 'nombre de noeud dans le réseau'
proc main_simNodes {} {
	global _NbNodeMin _NbNodeMax _NbNodeInc \
			CST_NodeSpeed CST_NbPacketSent
	
	# pour tous les noeuds
	for {set n $_NbNodeMin} {$n <= $_NbNodeMax} {set n [expr $n+$_NbNodeInc]} {
		# simulation
		sim_run $n $CST_NodeSpeed $CST_NbPacketSent AODV
		sim_run $n $CST_NodeSpeed $CST_NbPacketSent DSDV
		sim_run $n $CST_NodeSpeed $CST_NbPacketSent DSR
		sim_run $n $CST_NodeSpeed $CST_NbPacketSent OLSR
		
		# extraction des données
		exec python3 "script_extract1.py" AODV Node $n
		exec python3 "script_extract1.py" DSDV Node $n
		exec python3 "script_extract1.py" DSR Node $n
		exec python3 "script_extract1.py" OLSR Node $n
	}
}

# lance les simulations pour la métrique 'nombre de paquet à envoyer par communication'
proc main_simPackets {} {
	global _NbPacketSentMin _NbPacketSentMax _NbPacketSentInc \
			CST_NbNode CST_NodeSpeed
			
	# pour tous les quotas de paquet à envoyer
	for {set n $_NbPacketSentMin} {$n <= $_NbPacketSentMax} {set n [expr $n+$_NbPacketSentInc]} {
		# simulation
		sim_run $CST_NbNode $CST_NodeSpeed $n AODV
		sim_run $CST_NbNode $CST_NodeSpeed $n DSDV
		sim_run $CST_NbNode $CST_NodeSpeed $n DSR
		sim_run $CST_NbNode $CST_NodeSpeed $n OLSR
		
		# extraction des données
		exec python3 "script_extract1.py" AODV Packet $n
		exec python3 "script_extract1.py" DSDV Packet $n
		exec python3 "script_extract1.py" DSR Packet $n
		exec python3 "script_extract1.py" OLSR Packet $n
	}
}

# lance les simulations pour la métrique 'vitesse de déplacement des noeuds'
proc main_simSpeeds {} {
	global _NodeSpeedMin _NodeSpeedMax _NodeSpeedInc \
			CST_NbNode CST_NbPacketSent
			
	# pour tous les vitesses de déplacement
	for {set n $_NodeSpeedMin} {$n <= $_NodeSpeedMax} {set n [expr $n+$_NodeSpeedInc]} {
		# simulation
		sim_run $CST_NbNode $n $CST_NbPacketSent AODV
		sim_run $CST_NbNode $n $CST_NbPacketSent DSDV
		sim_run $CST_NbNode $n $CST_NbPacketSent DSR
		sim_run $CST_NbNode $n $CST_NbPacketSent OLSR
		
		# extraction des données
		exec python3 "script_extract1.py" AODV Speed $n
		exec python3 "script_extract1.py" DSDV Speed $n
		exec python3 "script_extract1.py" DSR Speed $n
		exec python3 "script_extract1.py" OLSR Speed $n
	}
}

# fusionne les résultats des diverses simulations (mise en forme par script_extract1.py)
proc main_pyMerge {} {
	puts "+>\tFUSION DES GRAPHES..."
	
	# fusion des graphes
	exec python3 "script_merge2.py" avg
	exec python3 "script_merge2.py" min
	exec python3 "script_merge2.py" max
	
	puts "+>\tFUSION DES GRAPHES TERMINÉE"
}

# vérifie et supprime les éventuelles fichiers de travail qui seront créés par script_extract1.py
proc main_checkWorkingFilesExist {} {
	exec python3 "script_eraseWorkingFiles3.py" AODV Node
	exec python3 "script_eraseWorkingFiles3.py" DSDV Node
	exec python3 "script_eraseWorkingFiles3.py" DSR Node
	exec python3 "script_eraseWorkingFiles3.py" OLSR Node
	
	exec python3 "script_eraseWorkingFiles3.py" AODV Packet
	exec python3 "script_eraseWorkingFiles3.py" DSDV Packet
	exec python3 "script_eraseWorkingFiles3.py" DSR Packet
	exec python3 "script_eraseWorkingFiles3.py" OLSR Packet
	
	exec python3 "script_eraseWorkingFiles3.py" AODV Speed
	exec python3 "script_eraseWorkingFiles3.py" DSDV Speed
	exec python3 "script_eraseWorkingFiles3.py" DSR Speed
	exec python3 "script_eraseWorkingFiles3.py" OLSR Speed
}

# lance la visualisation des graphes fusionnés créés en fin
proc main_runXGraph {} {
	global _FILEPATH_XGRAPH _VIEW_XGRAPH_END
	
	if {$_VIEW_XGRAPH_END} then {
		puts "+>\tAFFICHAGE DES RÉSULTATS XGRAPH"
		
		# cas moyen
		exec $_FILEPATH_XGRAPH outPY_TPP.Node.avg.tr &
		exec $_FILEPATH_XGRAPH outPY_TPP.Packet.avg.tr &
		exec $_FILEPATH_XGRAPH outPY_TPP.Speed.avg.tr &
		
		# meilleur des cas
#		exec $_FILEPATH_XGRAPH outPY_TPP.Node.min.tr &
#		exec $_FILEPATH_XGRAPH outPY_TPP.Packet.min.tr &
#		exec $_FILEPATH_XGRAPH outPY_TPP.Speed.min.tr &
		
		# pire des cas
#		exec $_FILEPATH_XGRAPH outPY_TPP.Node.max.tr &
#		exec $_FILEPATH_XGRAPH outPY_TPP.Packet.max.tr &
#		exec $_FILEPATH_XGRAPH outPY_TPP.Speed.max.tr &
	}
}



###########################################################################

###########################################################################





#
#	SCRIPT PRINCIPAL
#
###########################################################################

	
	# variables de travail
	array set nodes {}
	array set sinks {}
	array set agents {}
	array set traffics {}
	set NbSimDone 0
	
	# calcul du temps total de simulation (ici temps courant)
	set TotalTime [clock clicks -millisec]
	puts "+>\tDEBUT "
	
#	# test d'une simulation isolée :
#	sim_run 20 35 500 DSR		;# sim_run { _NbNode _NodeSpeed _NbPacketSent _Prtcl }

	# vérifications
	puts "+>\tVERIFICATION DE NON EXISTANCE DES FICHIERS DE TRAVAIL..."
	main_checkWorkingFilesExist

	# simulations :
	puts "+>\tLANCEMENT DES SIMULATIONS..."
	set TotalNodesTime [clock clicks -millisec]
	main_simNodes
	set TotalNodesTime [expr { ( [clock clicks -millisec] - $TotalNodesTime )/1000.0 }]
	
	set TotalPacketsTime [clock clicks -millisec]
	main_simPackets
	set TotalPacketsTime [expr { ( [clock clicks -millisec] - $TotalPacketsTime )/1000.0 }]
	
	set TotalSpeedsTime [clock clicks -millisec]
	main_simSpeeds
	set TotalSpeedsTime [expr { ( [clock clicks -millisec] - $TotalSpeedsTime )/1000.0 }]
	puts "+>\tSIMULATION TERMINÉE"
	
	# compilation des résultats
	main_pyMerge
	
	puts "+>\tFIN"
	puts "----------------------------------------------------------------------"
	set TotalTime [expr { ( [clock clicks -millisec] -$TotalTime)/1000.0 }]
	puts stderr "Temps d'exécution des simulations sur les noeuds : $TotalNodesTime sec (~[expr round($TotalNodesTime / 60.0)] min)"
	puts stderr "Temps d'exécution des simulations sur les paquets : $TotalPacketsTime sec (~[expr round($TotalPacketsTime / 60.0)] min)"
	puts stderr "Temps d'exécution des simulations sur les vitesses : $TotalSpeedsTime sec (~[expr round($TotalSpeedsTime / 60.0)] min)"
	puts stderr "Temps total d'exécution : $TotalTime sec (~[expr round($TotalTime / 60.0)] min)"
	
	# affichage des résultats
	main_runXGraph

	# on quitte NS
	exit 0

###########################################################################











