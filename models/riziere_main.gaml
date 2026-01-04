/**
* Name: rizieremain
* Author: Heritier Hamba 
* Modèle de gestion des rizières face à la salinisation
* Delta du Mékong - Vietnam
*/

model riziere_delta_mekong

global {
    // ============ PARAMETRES GLOBAUX ============
    
    // Dimensions environnement
    int largeur_grille <- 50;
    int hauteur_grille <- 50;
    float taille_cellule <- 100.0; // mètres
    
    // Populations initiales
    int nb_agriculteurs <- 20;
    int nb_parcelles <- 100;
    int nb_canaux <- 5;
    int nb_capteurs <- 3;
    int nb_conseillers <- 1;
    
    // Paramètres temporels
    int jour_simulation <- 0;
    int saison <- 1; // 1=sèche, 2=pluies, 3=récolte
    float cycle_saison <- 120.0; // jours
    
    // Paramètres environnementaux
    float intensite_maree <- 0.0; // 0-1
    float niveau_pluie <- 0.0; // mm/jour
    float temperature <- 30.0; // °C
    float evaporation_base <- 5.0; // mm/jour
    
    // Paramètres économiques
    float prix_riz_tonne <- 5000000.0; // VND
    float cout_irrigation_m3 <- 500.0; // VND
    
    // Seuils critiques
    float seuil_salinite_critique <- 4.0; // g/L
    float seuil_eau_minimum <- 5.0; // cm
    
    // Variables de suivi
    float salinite_moyenne <- 0.0;
    float rendement_total <- 0.0;
    int nb_parcelles_degradees <- 0;
    
    
    // ============ INITIALISATION ============
    
    init {
	    write "=== INITIALISATION SIMULATION RIZIERES ===";
	    write "Dimensions: " + string(largeur_grille) + "x" + string(hauteur_grille);
	    
	    // Initialisation de la grille
	    ask zone_terre {
	        salinite_sol <- rnd(0.5, 2.0);
	    }
	    
	    // Création des canaux
	    create canal number: nb_canaux {
	        location <- {rnd(float(largeur_grille) * taille_cellule), 
	                     rnd(float(hauteur_grille) * taille_cellule)};
	        distance_mer <- rnd(5.0, 50.0);
	        
	        if distance_mer < 20.0 {
	            salinite_eau <- rnd(2.0, 5.0);
	        } else {
	            salinite_eau <- rnd(0.5, 2.0);
	        }
	        
	        etat_ecluse <- true;
	        parcelles_connectees <- [];
	        
	        write "Canal " + string(name) + " créé à " + string(distance_mer) + "km de la mer";
	    }
	    
	    // Création des parcelles
	    create parcelle number: nb_parcelles {
	        location <- {rnd(float(largeur_grille) * taille_cellule), 
	                     rnd(float(hauteur_grille) * taille_cellule)};
	        taille <- rnd(0.5, 2.0);
	        salinite <- rnd(0.5, 3.0);
	        niveau_eau <- rnd(5.0, 15.0);
	        stade_croissance <- 0;
	        
	        if flip(0.7) {
	            type_riz <- "traditionnel";
	            rendement_potentiel <- 5.0;
	        } else {
	            type_riz <- "resistant_sel";
	            rendement_potentiel <- 6.0;
	        }
	        
	        rendement_reel <- 0.0;
	        
	        canal_connecte <- canal closest_to self;
	        if canal_connecte != nil {
	            ask canal_connecte {
	                parcelles_connectees <- parcelles_connectees + myself;
	            }
	        }
	    }
	    
	    // Création des agriculteurs
	    create agriculteur number: nb_agriculteurs {
	        location <- {rnd(float(largeur_grille) * taille_cellule), 
	                     rnd(float(hauteur_grille) * taille_cellule)};
	        capital <- rnd(10000000.0, 50000000.0);
	        experience <- rnd(1, 20);
	        
	        if experience < 5 {
	            strategie <- "suiveur";
	        } else if experience < 10 {
	            strategie <- "prudent";
	        } else {
	            strategie <- "optimiste";
	        }
	        
	        connaissances_salinite <- float(experience) / 20.0;
	        a_pompe <- flip(0.6);
	        mes_parcelles <- [];
	        
	        int nb_parcelles_attribuees <- rnd(2, 5);
	        list<parcelle> parcelles_disponibles <- list<parcelle>(parcelle where (each.proprietaire = nil));
	        
	        loop times: nb_parcelles_attribuees {
	            if !empty(parcelles_disponibles) {
	                parcelle p <- one_of(parcelles_disponibles);
	                p.proprietaire <- self;
	                mes_parcelles <- mes_parcelles + p;
	                parcelles_disponibles <- parcelles_disponibles - p;
	            }
	        }
	        
	        voisins <- list<agriculteur>((agriculteur at_distance 1000.0) - self);
	        
	        write "Agriculteur " + string(name) + " (" + strategie + ") avec " 
	              + string(length(mes_parcelles)) + " parcelles";
	    }
	    
	    // Création des capteurs
	    create capteur number: nb_capteurs {
	        location <- {rnd(float(largeur_grille) * taille_cellule), 
	                     rnd(float(hauteur_grille) * taille_cellule)};
	        rayon_mesure <- 2000.0;
	        frequence_mesure <- 24;
	    }
	    
	    // Création des conseiller
	    create conseiller number: nb_conseillers {
	        location <- {(float(largeur_grille) * taille_cellule)/2.0, 
	                     (float(hauteur_grille) * taille_cellule)/2.0};
	        expertise_salinite <- 0.9;
	    }
	    
	    write "=== INITIALISATION TERMINEE ===";
	    write "Agriculteurs: " + string(nb_agriculteurs);
	    write "Parcelles: " + string(nb_parcelles);
	    write "Canaux: " + string(nb_canaux);
	    write "";
	}
    
    
    // ============ DYNAMIQUE GLOBALE ============
    
    reflex mise_a_jour_environnement {
        jour_simulation <- jour_simulation + 1;
        
        // Cycle des saisons (120 jours)
        int jour_dans_cycle <- jour_simulation mod int(cycle_saison);
        
        if jour_dans_cycle < 40 {
            saison <- 1; // Saison sèche
            niveau_pluie <- rnd(0.0, 5.0);
            intensite_maree <- 0.7 + 0.3 * cos((jour_simulation * 2 * #pi) / 28); // Cycle lunaire
        } else if jour_dans_cycle < 80 {
            saison <- 2; // Saison pluies
            niveau_pluie <- rnd(20.0, 80.0);
            intensite_maree <- 0.3 + 0.2 * cos((jour_simulation * 2 * #pi) / 28);
        } else {
            saison <- 3; // Récolte
            niveau_pluie <- rnd(5.0, 15.0);
            intensite_maree <- 0.5 + 0.3 * cos((jour_simulation * 2 * #pi) / 28);
        }
        
        temperature <- 25 + 10 * sin((jour_simulation * 2 * #pi) / 365);
    }
    
    reflex calculer_indicateurs {
        salinite_moyenne <- mean(parcelle collect each.salinite);
        nb_parcelles_degradees <- parcelle count (each.salinite > seuil_salinite_critique);
        rendement_total <- sum(parcelle collect each.rendement_reel);
    }
    
    reflex afficher_stats when: every(30 #cycles) {
        write "=== JOUR " + jour_simulation + " - SAISON " + saison + " ===";
        write "Salinité moyenne: " + salinite_moyenne with_precision 2 + " g/L";
        write "Parcelles dégradées: " + nb_parcelles_degradees + "/" + nb_parcelles;
        write "Rendement total: " + rendement_total with_precision 1 + " tonnes";
        write "Marée: " + intensite_maree with_precision 2 + " | Pluie: " + niveau_pluie with_precision 1 + "mm";
        write "";
    }
}


// ============ GRILLE ENVIRONNEMENT ============

grid zone_terre width: largeur_grille height: hauteur_grille {
    float salinite_sol <- 0.0;
    
    rgb color <- rgb(34, 139, 34) update: calcul_couleur_sol();
    
    rgb calcul_couleur_sol {
        if salinite_sol < 2.0 {
            return rgb(34, 139, 34);      // vert foncé
        } else if salinite_sol < 4.0 {
            return rgb(154, 205, 50);      // vert clair
        } else if salinite_sol < 6.0 {
            return rgb(255, 255, 0);       // jaune
        } else {
            return rgb(255, 140, 0);       // orange
        }
    }
}


// ============ SPECIES PARCELLE ============

species parcelle {
    // Attributs
    float taille;
    float salinite;
    float niveau_eau;
    int stade_croissance;
    string type_riz;
    float rendement_potentiel;
    float rendement_reel;
    agriculteur proprietaire;
    canal canal_connecte;
    
    // Aspect visuel
    rgb couleur_parcelle <- #green;

	reflex actualiser_couleur {
	    if salinite < 2.0 {
	        couleur_parcelle <- #darkgreen;
	    } else if salinite < 4.0 {
	        couleur_parcelle <- #lightgreen;
	    } else if salinite < 8.0 {
	        couleur_parcelle <- #yellow;
	    } else {
	        couleur_parcelle <- #orange;
	    }
	}
    
    // Evolution de la salinité
    reflex evoluer_salinite {
        // Apport salinité par marée via canal
        if canal_connecte != nil {
            float apport_canal <- canal_connecte.salinite_eau * intensite_maree * 0.1;
            salinite <- salinite + apport_canal;
        }
        
        // Évaporation augmente salinité
        float evaporation <- evaporation_base * (1 - niveau_pluie / 100);
        salinite <- salinite + evaporation * 0.05;
        
        // Pluie dilue salinité
        salinite <- salinite * (1 - niveau_pluie / 200);
        
        // Consommation eau par riz
        if stade_croissance > 0 and niveau_eau > 0 {
            niveau_eau <- niveau_eau - 0.5;
        }
        
        // Apport pluie
        niveau_eau <- niveau_eau + niveau_pluie / 10;
        
        // Limites
        salinite <- max(0.0, min(100.0, salinite));
        niveau_eau <- max(0.0, min(50.0, niveau_eau));
    }
    
    // Croissance du riz
    reflex croitre when: stade_croissance < 120 {
        if niveau_eau > seuil_eau_minimum and salinite < 8.0 {
            float vitesse_croissance <- 1.0;
            
            // Ralentissement si conditions sous-optimales
            if salinite > 4.0 {
                vitesse_croissance <- vitesse_croissance * (1 - (salinite - 4) / 10);
            }
            
            if type_riz = "resistant_sel" {
                vitesse_croissance <- vitesse_croissance * 1.2;
            }
            
            stade_croissance <- int(stade_croissance + vitesse_croissance);
        }
    }
    
    // Calcul rendement à maturité
    reflex calculer_rendement when: stade_croissance = 120 {
	    // Facteur eau
	    float facteur_eau <- 1.0;
	    if niveau_eau <= 10 {
	        facteur_eau <- niveau_eau / 10;
	    }
	    
	    // Facteur salinité
	    float facteur_salinite <- 1.0;
	    if salinite < 2.0 {
	        facteur_salinite <- 1.0;
	    } else if salinite < 4.0 {
	        facteur_salinite <- 0.8;
	    } else if salinite < 6.0 {
	        facteur_salinite <- 0.5;
	    } else {
	        facteur_salinite <- 0.2;
	    }
	
	    rendement_reel <- rendement_potentiel * taille * facteur_eau * facteur_salinite;
	    stade_croissance <- 0;
	}
    
    // Recevoir irrigation
    action recevoir_irrigation(float volume, float salinite_apport) {
        niveau_eau <- niveau_eau + volume;
        salinite <- (salinite * niveau_eau + salinite_apport * volume) / (niveau_eau + volume);
    }
    
    aspect default {
        draw circle(50) color: couleur_parcelle border: #black;
    }
}


// ============ SPECIES AGRICULTEUR ============

species agriculteur skills: [moving] {
    // Attributs
    float capital;
    int experience;
    string strategie; // "prudent", "optimiste", "suiveur"
    float connaissances_salinite;
    list<parcelle> mes_parcelles;
    list<agriculteur> voisins;
    bool a_pompe;
    
    // Mémoire
    map<int, float> historique_salinite;
    int nb_irrigations_saison <- 0;
    
    // Seuils de décision
    float seuil_salinite <- 2.5;

	reflex initialiser_seuil when: cycle = 0 {
	    if strategie = "prudent" {
	        seuil_salinite <- 2.0;
	    } else if strategie = "optimiste" {
	        seuil_salinite <- 3.5;
	    } else {
	        seuil_salinite <- 2.5;
	    }
	}
    // Observation et décision
    reflex gerer_parcelles {
        loop p over: mes_parcelles {
            // Décision d'irrigation
            if p.salinite > seuil_salinite or p.niveau_eau < seuil_eau_minimum {
                if capital > cout_irrigation_m3 * 100 and a_pompe {
                    do irriguer(p);
                }
            }
        }
    }
    
    // Action irrigation
    action irriguer(parcelle p) {
        float volume_irrigation <- 20.0; // cm d'eau
        float cout <- volume_irrigation * cout_irrigation_m3;
        
        if capital >= cout {
            capital <- capital - cout;
            ask p {
                do recevoir_irrigation(volume_irrigation, 0.5); // Eau douce peu salée
            }
            nb_irrigations_saison <- nb_irrigations_saison + 1;
        }
    }
    
    // Communication avec voisins
    reflex echanger_informations when: every(7 #cycles) {
        if !empty(voisins) and strategie = "suiveur" {
            float salinite_moy_voisins <- mean(voisins collect (mean(each.mes_parcelles collect each.salinite)));
            seuil_salinite <- (seuil_salinite + salinite_moy_voisins) / 2;
        }
    }
    
    // Apprentissage
    reflex apprendre when: saison = 3 and every(120 #cycles) {
        float rendement_moyen <- mean(mes_parcelles collect each.rendement_reel);
        
        if rendement_moyen < 3.0 { // Mauvais rendement
            // Ajuster stratégie
            if strategie = "optimiste" {
                seuil_salinite <- seuil_salinite - 0.5;
            }
            connaissances_salinite <- min(1.0, connaissances_salinite + 0.05);
        }
    }
    
    rgb ma_couleur <- #yellow;

	reflex actualiser_couleur when: cycle = 0 {
	    if strategie = "prudent" {
	        ma_couleur <- #blue;
	    } else if strategie = "optimiste" {
	        ma_couleur <- #red;
	    } else {
	        ma_couleur <- #yellow;
	    }
	}
	
	aspect default {
	    draw triangle(200) color: ma_couleur border: #black;
	    draw circle(100) at: location color: #white;
	}
}


// ============ SPECIES CANAL ============

species canal {
    // Attributs
    float distance_mer;
    float salinite_eau;
    bool etat_ecluse;
    list<parcelle> parcelles_connectees;
    float debit_actuel;
    
    // Propagation salinité
    reflex propager_salinite {
        if etat_ecluse {
            // Remontée salinité selon marée et distance mer
            float augmentation <- intensite_maree * (1 / distance_mer) * 2.0;
            salinite_eau <- min(35.0, salinite_eau + augmentation);
        } else {
            // Dilution progressive si écluse fermée
            salinite_eau <- max(0.5, salinite_eau * 0.95);
        }
    }
    
    // Gestion collective écluse
    reflex gerer_ecluse when: every(7 #cycles) {
        list<agriculteur> agriculteurs_concernes <- (parcelles_connectees collect each.proprietaire);
        int votes_fermeture <- 0;
        
        loop ag over: agriculteurs_concernes {
            float salinite_moy <- mean(ag.mes_parcelles collect each.salinite);
            if salinite_moy > 3.0 {
                votes_fermeture <- votes_fermeture + 1;
            }
        }
        
        etat_ecluse <- votes_fermeture < length(agriculteurs_concernes) / 2;
    }
    
    aspect default {
        draw square(300) color: etat_ecluse ? #blue : #red border: #black;
    }
}


// ============ SPECIES CAPTEUR ============

species capteur {
    float rayon_mesure;
    int frequence_mesure;
    
    reflex mesurer when: every(frequence_mesure #cycles) {
        list<parcelle> parcelles_proches <- parcelle at_distance rayon_mesure;
        
        if !empty(parcelles_proches) {
            float salinite_detectee <- mean(parcelles_proches collect each.salinite);
            
            // Alerte si dépassement seuil
            if salinite_detectee > seuil_salinite_critique {
                list<agriculteur> a_alerter <- (parcelles_proches collect each.proprietaire);
                
                ask a_alerter {
                    // Réduire seuil de tolérance
                    seuil_salinite <- max(1.5, seuil_salinite - 0.2);
                }
            }
        }
    }
    
    aspect default {
        draw circle(rayon_mesure) color: #cyan border: #blue empty: true;
        draw sphere(150) color: #cyan;
    }
}


// ============ SPECIES CONSEILLER ============

species conseiller {
    float expertise_salinite;
    
    // Création une géométrie d'étoile
    geometry forme_etoile <- nil;
    
    init {
        // Création une étoile à 5 branches
        float rayon_ext <- 300.0;
        float rayon_int <- 120.0;
        list<point> points_etoile <- [];
        
        loop i from: 0 to: 9 {
            float angle <- i * 36.0;
            float rayon <- (i mod 2 = 0) ? rayon_ext : rayon_int;
            float x <- rayon * cos(angle);
            float y <- rayon * sin(angle);
            points_etoile <- points_etoile + {x, y};
        }
        
        forme_etoile <- polygon(points_etoile);
    }
    
    reflex former_agriculteurs when: every(30 #cycles) {
        list<agriculteur> agriculteurs_novices <- agriculteur where (each.experience < 5);
        
        ask agriculteurs_novices {
            connaissances_salinite <- min(1.0, connaissances_salinite + 0.1);
            
            float rendement_moyen <- mean(mes_parcelles collect each.rendement_reel);
            if rendement_moyen < 2.0 {
                strategie <- "prudent";
                seuil_salinite <- 2.0;
            }
        }
    }
    
    aspect default {
        draw forme_etoile color: #gold border: #black at: location;
    }
}

// ============ EXPERIMENT SIMULATION ============

experiment Simulation_Rizieres type: gui {
    
    // Paramètres modifiables
    parameter "Nombre d'agriculteurs" var: nb_agriculteurs min: 10 max: 50 category: "Population";
    parameter "Nombre de parcelles" var: nb_parcelles min: 50 max: 200 category: "Population";
    parameter "Nombre de canaux" var: nb_canaux min: 3 max: 10 category: "Infrastructure";
    parameter "Seuil salinité critique (g/L)" var: seuil_salinite_critique min: 2.0 max: 8.0 category: "Environnement";
    parameter "Évaporation de base (mm/j)" var: evaporation_base min: 2.0 max: 10.0 category: "Environnement";
    
    output {
        
        // Affichage principal 2D
        display "Delta du Mékong - Rizières" type: 2d {
            grid zone_terre lines: #black;
            species parcelle aspect: default;
            species canal aspect: default;
            species agriculteur aspect: default;
            species capteur aspect: default;
            species conseiller aspect: default;
        }
        
        // Graphique salinité
        display "Évolution Salinité" refresh: every(1 #cycles) {
            chart "Salinité moyenne du delta" type: series size: {1.0, 0.5} position: {0, 0} {
                data "Salinité (g/L)" value: salinite_moyenne color: #red marker: false;
                data "Seuil critique" value: seuil_salinite_critique color: #orange marker: false;
            }
        }
        
        // Graphique rendements
        display "Rendements" refresh: every(10 #cycles) {
            chart "Production de riz" type: series size: {1.0, 0.5} position: {0, 0.5} {
                data "Rendement total (tonnes)" value: rendement_total color: #green marker: false;
            }
        }
        
        // Graphique parcelles dégradées
        display "État des parcelles" refresh: every(1 #cycles) {
            chart "Parcelles dégradées par salinité" type: series {
                data "Nb parcelles dégradées" value: nb_parcelles_degradees color: #orange marker: false;
                data "Total parcelles" value: nb_parcelles color: #gray marker: false;
            }
        }
        
        // Graphique conditions environnementales
        display "Conditions Environnementales" refresh: every(1 #cycles) {
            chart "Marée et Saison" type: series {
                data "Intensité marée" value: intensite_maree color: #blue marker: false;
                data "Saison" value: saison color: #purple marker: false;
            }
        }
        
        // Moniteurs temps réel
        monitor "Jour de simulation" value: jour_simulation refresh: every(1 #cycles);
        monitor "Saison actuelle" value: saison = 1 ? "Sèche" : (saison = 2 ? "Pluies" : "Récolte") refresh: every(1 #cycles);
        monitor "Salinité moyenne (g/L)" value: salinite_moyenne with_precision 2 refresh: every(1 #cycles);
        monitor "Parcelles dégradées" value: nb_parcelles_degradees refresh: every(1 #cycles);
        monitor "% Parcelles dégradées" value: (nb_parcelles_degradees / nb_parcelles * 100) with_precision 1 refresh: every(1 #cycles);
        monitor "Rendement total (tonnes)" value: rendement_total with_precision 1 refresh: every(10 #cycles);
        monitor "Intensité marée" value: intensite_maree with_precision 2 refresh: every(1 #cycles);
        monitor "Pluie (mm/j)" value: niveau_pluie with_precision 1 refresh: every(1 #cycles);
        monitor "Température (°C)" value: temperature with_precision 1 refresh: every(1 #cycles);
    }
}
