/**
* Name: rizieremain
* Author: Heritier Hamba 
* Modèle de gestion des rizières face à la salinisation
* Delta du Mékong - Vietnam
*/


model riziere_delta_mekong

global {
    // ============ PARAMETRES GLOBAUX ============
    
    int largeur_grille <- 50;
    int hauteur_grille <- 50;
    float taille_cellule <- 100.0;
    
    int nb_agriculteurs <- 20;
    int nb_parcelles <- 100;
    int nb_canaux <- 5;
    int nb_capteurs <- 3;
    int nb_conseillers <- 1;
    
    int jour_simulation <- 0;
    int saison <- 1;
    int numero_saison_globale <- 0;
    float cycle_saison <- 120.0;
    
    float intensite_maree <- 0.0;
    float niveau_pluie <- 0.0;
    float temperature <- 30.0;
    float evaporation_base <- 5.0;
    
    float prix_riz_tonne <- 8000000.0;
    float cout_irrigation_m3 <- 200.0;
    
    float seuil_salinite_critique <- 4.0;
    float seuil_eau_minimum <- 5.0;
    
    float salinite_moyenne <- 0.0;
    float rendement_total <- 0.0;
    int nb_parcelles_degradees <- 0;
    
    // Statistiques transitions
    int nb_transitions_total <- 0;
    int nb_transitions_vers_prudent <- 0;
    int nb_transitions_vers_optimiste <- 0;
    
    // Statistiques économiques
    float capital_total <- 0.0;
    float capital_moyen <- 0.0;
    int nb_agriculteurs_pauvres <- 0;
    int nb_agriculteurs_riches <- 0;
    
    // Système de faillite
    float seuil_faillite <- 5000000.0;  // 5M VND minimum
    int nb_faillites <- 0;
    
    // Système de subventions
    float montant_subvention <- 10000000.0;  // 10M VND
    float seuil_subvention <- 15000000.0;    // Aide si < 15M VND
    
    init {
        write "=== INITIALISATION SIMULATION RIZIERES ===";
        write "Dimensions: " + largeur_grille + "x" + hauteur_grille;
        
        ask zone_terre {
            salinite_sol <- rnd(0.5, 2.0);
        }
        
        create canal number: nb_canaux {
            location <- {rnd(float(largeur_grille)), rnd(float(hauteur_grille))};
            distance_mer <- rnd(5.0, 50.0);
            
            if distance_mer < 20.0 {
                salinite_eau <- rnd(2.0, 5.0);
            } else {
                salinite_eau <- rnd(0.5, 2.0);
            }
            
            etat_ecluse <- true;
            parcelles_connectees <- [];
            
            write "Canal " + name + " créé à " + distance_mer + "km de la mer";
        }
        
        create parcelle number: nb_parcelles {
            location <- {rnd(float(largeur_grille)), rnd(float(hauteur_grille))};
            taille <- rnd(0.5, 2.0);
            salinite <- rnd(0.5, 3.0);
            niveau_eau <- rnd(5.0, 15.0);
            
            // Initialiser avec croissance aléatoire
            stade_croissance <- rnd(0, 90);  // 0-90 jours déjà écoulés
            
            if flip(0.7) {
                type_riz <- "traditionnel";
                rendement_potentiel <- 5.0;
            } else {
                type_riz <- "resistant_sel";
                rendement_potentiel <- 6.0;
            }
            
            rendement_reel <- 0.0;
            rendement_saison <- 0.0;
            
            canal_connecte <- canal closest_to self;
            if canal_connecte != nil {
                ask canal_connecte {
                    parcelles_connectees <- parcelles_connectees + myself;
                }
            }
        }
        
        create agriculteur number: nb_agriculteurs {
            location <- {rnd(float(largeur_grille)), rnd(float(hauteur_grille))};
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
            
            voisins <- list<agriculteur>((agriculteur at_distance 10.0) - self);
            
            write "Agriculteur " + name + " (" + strategie + ") avec " + length(mes_parcelles) + " parcelles";
        }
        
        create capteur number: nb_capteurs {
            location <- {rnd(float(largeur_grille)), rnd(float(hauteur_grille))};
            rayon_mesure <- 10.0;
            frequence_mesure <- 24;
        }
        
        create conseiller number: nb_conseillers {
            location <- {float(largeur_grille)/2.0, float(hauteur_grille)/2.0};
            expertise_salinite <- 0.9;
        }
        
        write "=== INITIALISATION TERMINEE ===";
        write "Parcelles initialisées avec croissance variable (0-90 jours)";
        write "";
    }
    
    reflex mise_a_jour_environnement {
        jour_simulation <- jour_simulation + 1;
        
        int jour_dans_cycle <- jour_simulation mod int(cycle_saison);
        
        // Déterminer saison et paramètres
        if jour_dans_cycle < 40 {
            saison <- 1;
            niveau_pluie <- rnd(0.0, 5.0);
        } else if jour_dans_cycle < 80 {
            saison <- 2;
            niveau_pluie <- rnd(20.0, 80.0);
        } else {
            saison <- 3;
            niveau_pluie <- rnd(5.0, 15.0);
        }
        
        // Calcul marée et température
        intensite_maree <- 0.5 + 0.3 * cos(jour_simulation * 360.0 / 28.0);
        temperature <- 25.0 + 10.0 * sin(jour_simulation * 360.0 / 365.0);
        
        // FIN DE CYCLE : Évaluations
        if jour_dans_cycle = 119 {
            numero_saison_globale <- numero_saison_globale + 1;
            write "";
            write "╔═══════════════════════════════════════════════════╗";
            write "║  FIN CYCLE " + numero_saison_globale + " (Jour " + jour_simulation + ")";
            write "╚═══════════════════════════════════════════════════╝";
            write "";
            
            ask agriculteur {
                do evaluer_maintenant();
            }
            
            write "";
            write "✓ Évaluations terminées - Nouveau cycle démarre";
            write "═══════════════════════════════════════════════════";
            write "";
        }
    }
    
    reflex calculer_indicateurs {
        salinite_moyenne <- mean(parcelle collect each.salinite);
        nb_parcelles_degradees <- parcelle count (each.salinite > seuil_salinite_critique);
        rendement_total <- sum(parcelle collect each.rendement_saison);
        
        // Statistiques économiques
        if !empty(agriculteur) {
            capital_total <- sum(agriculteur collect each.capital);
            capital_moyen <- mean(agriculteur collect each.capital);
            nb_agriculteurs_pauvres <- agriculteur count (each.capital < 15000000.0);
            nb_agriculteurs_riches <- agriculteur count (each.capital > 30000000.0);
        }
    }
    
    // Gestion des faillites
    reflex gerer_faillites when: every(30 #cycles) and jour_simulation > 240 {
        list<agriculteur> agriculteurs_ruines <- agriculteur where (each.capital < seuil_faillite);
        
        if !empty(agriculteurs_ruines) {
            write "";
            write "⚠️ FAILLITES DÉTECTÉES ⚠️";
            
            ask agriculteurs_ruines {
                write "💀 FAILLITE : " + name + " (capital=" + (capital/1000000 with_precision 1) + 
                      "M VND, parcelles=" + length(mes_parcelles) + ")";
                
                // Libérer les parcelles
                ask mes_parcelles {
                    proprietaire <- nil;
                    write "   → Parcelle " + name + " retourne à l'État";
                }
                
                nb_faillites <- nb_faillites + 1;
                
                // Supprimer l'agriculteur
                do die;
            }
            
            write "Total faillites : " + nb_faillites;
            write "";
        }
    }
    
    // Distribution de subventions
    reflex distribuer_subventions when: every(120 #cycles) and jour_simulation > 120 {
        
        list<agriculteur> agriculteurs_pauvres <- agriculteur where (
            each.capital < seuil_subvention
        );
        
        if !empty(agriculteurs_pauvres) {
            write "💰 SUBVENTIONS (Jour " + jour_simulation + ")";
            
            ask agriculteurs_pauvres {
                capital <- capital + montant_subvention;
                write "   → " + name + ": +" + (montant_subvention/1000000 with_precision 1) + "M VND";
            }
        }
    }
    
    reflex afficher_stats when: every(30 #cycles) {
        write "=== JOUR " + jour_simulation + " - SAISON " + saison + " ===";
        write "Salinité moyenne: " + (salinite_moyenne with_precision 2) + " g/L";
        write "Parcelles dégradées: " + nb_parcelles_degradees + "/" + nb_parcelles;
        write "Rendement total: " + (rendement_total with_precision 1) + " tonnes";
        write "Marée: " + (intensite_maree with_precision 2) + " | Pluie: " + (niveau_pluie with_precision 1) + "mm";
        
        int nb_prudents <- agriculteur count (each.strategie = "prudent");
        int nb_suiveurs <- agriculteur count (each.strategie = "suiveur");
        int nb_optimistes <- agriculteur count (each.strategie = "optimiste");
        
        write "Stratégies: " + nb_prudents + " Prudents | " + nb_suiveurs + " Suiveurs | " + nb_optimistes + " Optimistes";
        write "Transitions totales: " + nb_transitions_total;
        
        // Afficher économie
        write "Capital moyen: " + (capital_moyen/1000000 with_precision 1) + "M VND | " +
              "Pauvres: " + nb_agriculteurs_pauvres + " | Riches: " + nb_agriculteurs_riches +
              " | Faillites: " + nb_faillites;
        write "";
    }
}


grid zone_terre width: largeur_grille height: hauteur_grille {
    float salinite_sol <- 0.0;
    rgb color <- rgb(34, 139, 34);
    
    reflex actualiser_couleur {
        if salinite_sol < 2.0 {
            color <- rgb(34, 139, 34);
        } else if salinite_sol < 4.0 {
            color <- rgb(154, 205, 50);
        } else if salinite_sol < 6.0 {
            color <- rgb(255, 255, 0);
        } else {
            color <- rgb(255, 140, 0);
        }
    }
}


species parcelle {
    float taille;
    float salinite;
    float niveau_eau;
    int stade_croissance;
    string type_riz;
    float rendement_potentiel;
    float rendement_reel;
    float rendement_saison;
    agriculteur proprietaire;
    canal canal_connecte;
    
    rgb couleur_parcelle <- #green;
    
    reflex evoluer_salinite {
        if canal_connecte != nil {
            float apport_canal <- canal_connecte.salinite_eau * intensite_maree * 0.1;
            salinite <- salinite + apport_canal;
        }
        
        float evaporation <- evaporation_base * (1.0 - niveau_pluie / 100.0);
        salinite <- salinite + evaporation * 0.05;
        salinite <- salinite * (1.0 - niveau_pluie / 200.0);
        
        if stade_croissance > 0 and niveau_eau > 0 {
            niveau_eau <- niveau_eau - 0.5;
        }
        
        niveau_eau <- niveau_eau + niveau_pluie / 10.0;
        
        salinite <- max(0.0, min(35.0, salinite));
        niveau_eau <- max(0.0, min(50.0, niveau_eau));
    }
    
    reflex actualiser_couleur {
        if salinite < 2.0 {
            couleur_parcelle <- rgb(0, 100, 0);
        } else if salinite < 4.0 {
            couleur_parcelle <- rgb(144, 238, 144);
        } else if salinite < 8.0 {
            couleur_parcelle <- rgb(255, 255, 0);
        } else {
            couleur_parcelle <- rgb(255, 140, 0);
        }
    }
    
    reflex croitre when: stade_croissance < 120 {
        if niveau_eau > seuil_eau_minimum and salinite < 8.0 {
            float vitesse_croissance <- 1.0;
            
            if salinite > 4.0 {
                vitesse_croissance <- vitesse_croissance * (1.0 - (salinite - 4.0) / 10.0);
            }
            
            if type_riz = "resistant_sel" {
                vitesse_croissance <- vitesse_croissance * 1.2;
            }
            
            stade_croissance <- int(stade_croissance + vitesse_croissance);
        }
    }
    
    reflex calculer_rendement when: stade_croissance = 120 {
        float facteur_eau <- 1.0;
        if niveau_eau <= 10.0 {
            facteur_eau <- niveau_eau / 10.0;
        }
        
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
        rendement_saison <- rendement_saison + rendement_reel;
        
        // Message debug récolte
        if proprietaire != nil and rendement_reel > 0.1 {
            write "🌾 RÉCOLTE : Parcelle de " + proprietaire.name + " → " + 
                  (rendement_reel with_precision 2) + "t (sal=" + (salinite with_precision 1) + "g/L)";
        }
        
        stade_croissance <- 0;
    }
    
    action reset_saison {
        rendement_saison <- 0.0;
    }
    
    action recevoir_irrigation(float volume, float salinite_apport) {
        niveau_eau <- niveau_eau + volume;
        if niveau_eau > 0.0 {
            salinite <- (salinite * niveau_eau + salinite_apport * volume) / (niveau_eau + volume);
        }
    }
    
    aspect default {
        draw square(1) color: couleur_parcelle border: #black;
    }
}


species agriculteur skills: [moving] {
    // Attributs de base
    float capital;
    int experience;
    string strategie;
    float connaissances_salinite;
    list<parcelle> mes_parcelles;
    list<agriculteur> voisins;
    bool a_pompe;
    
    // Attributs visuels
    float seuil_salinite <- 2.5;
    rgb ma_couleur <- #yellow;
    
    // Historique performances
    list<float> rendements_saisons <- [];
    float rendement_saison_actuelle <- 0.0;
    
    // Compteurs pour transitions
    int nb_mauvaises_consecutives <- 0;
    int nb_bonnes_consecutives <- 0;
    int derniere_saison_evaluee <- 0;
    
    // Gestion transitions
    bool en_transition <- false;
    int jours_transition <- 0;
    string strategie_future <- "";
    float seuil_future <- 0.0;
    rgb couleur_cible <- #white;
    
    // Historique simplifié
    list<string> historique_transitions <- [];
    
    // Statistiques
    int nb_irrigations_saison <- 0;
    int nb_irrigations_total <- 0;
    
    
    reflex initialiser_parametres when: cycle = 0 {
        if strategie = "prudent" {
            seuil_salinite <- 2.0;
            ma_couleur <- #blue;
        } else if strategie = "optimiste" {
            seuil_salinite <- 3.5;
            ma_couleur <- #red;
        } else {
            seuil_salinite <- 2.5;
            ma_couleur <- #yellow;
        }
    }
    
    
    reflex gerer_parcelles {
        loop p over: mes_parcelles {
            if p.salinite > seuil_salinite or p.niveau_eau < seuil_eau_minimum {
                if capital > cout_irrigation_m3 * 100.0 and a_pompe {
                    do irriguer(p);
                }
            }
        }
    }
    
    action irriguer(parcelle p) {
        float volume_irrigation <- 20.0;
        float cout <- volume_irrigation * cout_irrigation_m3;
        
        if capital >= cout {
            capital <- capital - cout;
            ask p {
                do recevoir_irrigation(volume_irrigation, 0.5);
            }
            nb_irrigations_saison <- nb_irrigations_saison + 1;
            nb_irrigations_total <- nb_irrigations_total + 1;
        }
    }
    
    
    reflex echanger_informations when: every(7 #cycles) {
        if !empty(voisins) and strategie = "suiveur" {
            float salinite_moy_voisins <- mean(voisins collect (mean(each.mes_parcelles collect each.salinite)));
            seuil_salinite <- (seuil_salinite + salinite_moy_voisins) / 2.0;
        }
    }
    
    
    // Évaluation avec plus de détails
    action evaluer_maintenant {
        
        if derniere_saison_evaluee >= jour_simulation - 10 {
            return;
        }
        derniere_saison_evaluee <- jour_simulation;
        
        write "📊 ÉVALUATION : " + name + " (jour " + jour_simulation + ")";
        
        // 1. Calculer rendement CUMULÉ de la saison
        if !empty(mes_parcelles) {
            rendement_saison_actuelle <- mean(mes_parcelles collect each.rendement_saison);
        } else {
            rendement_saison_actuelle <- 0.0;
        }
        
        // Afficher détails par parcelle
        float salinite_moyenne_parcelles <- mean(mes_parcelles collect each.salinite);
        int nb_parcelles_productives <- mes_parcelles count (each.rendement_saison > 0.0);
        
        write "   Stratégie: " + strategie + 
              " | Rendement cumulé : " + (rendement_saison_actuelle with_precision 2) + " t/ha" +
              " | Capital: " + (capital/1000000 with_precision 1) + "M VND";
        write "   Parcelles productives: " + nb_parcelles_productives + "/" + length(mes_parcelles) +
              " | Salinité moyenne: " + (salinite_moyenne_parcelles with_precision 1) + " g/L";
        
        rendements_saisons <- rendements_saisons + rendement_saison_actuelle;
        
        
        // 2. Évaluer la performance
        bool mauvaise_saison <- rendement_saison_actuelle < 3.0;
        bool bonne_saison <- rendement_saison_actuelle > 5.0;
        bool excellente_saison <- rendement_saison_actuelle > 5.5;
        
        
        // 3. Mettre à jour compteurs
        if mauvaise_saison {
            nb_mauvaises_consecutives <- nb_mauvaises_consecutives + 1;
            nb_bonnes_consecutives <- 0;
            write "   → Mauvaise saison ! (compteur échecs: " + nb_mauvaises_consecutives + ")";
            
        } else if bonne_saison {
            nb_bonnes_consecutives <- nb_bonnes_consecutives + 1;
            nb_mauvaises_consecutives <- 0;
            write "   → Bonne saison ! (compteur succès: " + nb_bonnes_consecutives + ")";
            
        } else {
            nb_mauvaises_consecutives <- 0;
            nb_bonnes_consecutives <- 0;
            write "   → Saison moyenne (reset compteurs)";
        }
        
        
        // 4. Vérifier TRANSITION VERS PRUDENT
        if strategie = "optimiste" and nb_mauvaises_consecutives >= 1 {
            do declencher_transition("suiveur", "echec_repete", rendement_saison_actuelle);
            nb_mauvaises_consecutives <- 0;
            
        } else if strategie = "suiveur" and nb_mauvaises_consecutives >= 1 {
            do declencher_transition("prudent", "echec_repete", rendement_saison_actuelle);
            nb_mauvaises_consecutives <- 0;
        }
        
        // 5. Vérifier TRANSITION VERS OPTIMISTE
        else if strategie = "prudent" and nb_bonnes_consecutives >= 2 and bonne_saison {
            do declencher_transition("suiveur", "succes_repete", rendement_saison_actuelle);
            nb_bonnes_consecutives <- 0;
            
        } else if strategie = "suiveur" and nb_bonnes_consecutives >= 2 and excellente_saison {
            do declencher_transition("optimiste", "succes_repete", rendement_saison_actuelle);
            nb_bonnes_consecutives <- 0;
        }
        
        
        // 6. Apprentissage
        if mauvaise_saison {
            connaissances_salinite <- min(1.0, connaissances_salinite + 0.05);
        }
        
        
        // 7. Reset compteurs et parcelles pour nouvelle saison
        nb_irrigations_saison <- 0;
        ask mes_parcelles {
            do reset_saison();
        }
    }
    
    
    action declencher_transition(string nouvelle_strat, string cause, float rendement_declencheur) {
        
        // 1. Enregistrer dans historique
        string evenement <- "Jour " + jour_simulation + ": " + strategie + " → " + nouvelle_strat + 
                           " (cause: " + cause + ", rendement: " + (rendement_declencheur with_precision 1) + "t)";
        historique_transitions <- historique_transitions + evenement;
        
        
        // 2. Définir couleur et seuil cibles
        if nouvelle_strat = "prudent" {
            couleur_cible <- #blue;
            seuil_future <- 2.0;
        } else if nouvelle_strat = "suiveur" {
            couleur_cible <- #yellow;
            seuil_future <- 2.5;
        } else {
            couleur_cible <- #red;
            seuil_future <- 3.5;
        }
        
        
        // 3. Activer animation
        en_transition <- true;
        jours_transition <- 5;
        strategie_future <- nouvelle_strat;
        
        
        // 4. Statistiques globales
        nb_transitions_total <- nb_transitions_total + 1;
        if nouvelle_strat = "prudent" or (strategie = "optimiste" and nouvelle_strat = "suiveur") {
            nb_transitions_vers_prudent <- nb_transitions_vers_prudent + 1;
        } else {
            nb_transitions_vers_optimiste <- nb_transitions_vers_optimiste + 1;
        }
        
        
        // 5. Message console détaillé
        string emoji <- cause = "echec_repete" ? "🔻" : "📈";
        
        write "";
        write emoji + " TRANSITION DÉCLENCHÉE : " + name;
        write "   " + strategie + " → " + nouvelle_strat;
        write "   Cause : " + cause;
        write "   Rendement déclencheur : " + (rendement_declencheur with_precision 1) + " t/ha";
        write "   Nouveau seuil : " + (seuil_future with_precision 1) + " g/L (actuel: " + (seuil_salinite with_precision 1) + ")";
        write "   Capital restant : " + (capital / 1000000.0 with_precision 1) + "M VND";
        write "   Connaissances : " + (connaissances_salinite with_precision 2);
        write "";
    }
    
    
    reflex gerer_transition when: en_transition = true {
        
        float progression <- (5.0 - float(jours_transition)) / 5.0;
        
        int r_actuel <- int(ma_couleur.red);
        int g_actuel <- int(ma_couleur.green);
        int b_actuel <- int(ma_couleur.blue);
        
        int r_cible <- int(couleur_cible.red);
        int g_cible <- int(couleur_cible.green);
        int b_cible <- int(couleur_cible.blue);
        
        int r_nouveau <- int(r_actuel + (r_cible - r_actuel) * progression);
        int g_nouveau <- int(g_actuel + (g_cible - g_actuel) * progression);
        int b_nouveau <- int(b_actuel + (b_cible - b_actuel) * progression);
        
        ma_couleur <- rgb(r_nouveau, g_nouveau, b_nouveau);
        
        jours_transition <- jours_transition - 1;
        
        if jours_transition <= 0 {
            strategie <- strategie_future;
            seuil_salinite <- seuil_future;
            ma_couleur <- couleur_cible;
            en_transition <- false;
            
            write "✓ Transition terminée : " + name + " est maintenant " + strategie;
            write "";
        }
    }
    
    
    aspect default {
        float taille_triangle <- 0.5 + (capital / 50000000.0) * 0.5;
        taille_triangle <- max(0.5, min(1.5, taille_triangle));
        
        draw triangle(taille_triangle) color: ma_couleur border: #black;
        draw circle(0.3) at: location color: #white;
        
        if en_transition {
            draw "💡" size: 15 at: location + {0, -0.8} color: #white;
        }
    }
}


species canal {
    float distance_mer;
    float salinite_eau;
    bool etat_ecluse;
    list<parcelle> parcelles_connectees;
    
    reflex propager_salinite {
        if etat_ecluse {
            float augmentation <- intensite_maree * (1.0 / distance_mer) * 2.0;
            salinite_eau <- min(35.0, salinite_eau + augmentation);
        } else {
            salinite_eau <- max(0.5, salinite_eau * 0.95);
        }
    }
    
    reflex gerer_ecluse when: every(7 #cycles) {
        list<agriculteur> agriculteurs_concernes <- list<agriculteur>(parcelles_connectees collect each.proprietaire);
        int votes_fermeture <- 0;
        
        loop ag over: agriculteurs_concernes {
            if ag != nil {
                float salinite_moy <- mean(ag.mes_parcelles collect each.salinite);
                if salinite_moy > 3.0 {
                    votes_fermeture <- votes_fermeture + 1;
                }
            }
        }
        
        etat_ecluse <- votes_fermeture < length(agriculteurs_concernes) / 2;
    }
    
    aspect default {
        draw square(1.5) color: etat_ecluse ? #blue : #red border: #black;
    }
}


species capteur {
    float rayon_mesure;
    int frequence_mesure;
    
    reflex mesurer when: every(frequence_mesure #cycles) {
        list<parcelle> parcelles_proches <- parcelle at_distance rayon_mesure;
        
        if !empty(parcelles_proches) {
            float salinite_detectee <- mean(parcelles_proches collect each.salinite);
            
            if salinite_detectee > seuil_salinite_critique {
                list<agriculteur> a_alerter <- list<agriculteur>(parcelles_proches collect each.proprietaire);
                
                ask a_alerter {
                    if self != nil {
                        seuil_salinite <- max(1.5, seuil_salinite - 0.2);
                    }
                }
            }
        }
    }
    
    aspect default {
        draw circle(rayon_mesure) color: #cyan border: #blue empty: true;
        draw sphere(0.5) color: #cyan;
    }
}


species conseiller {
    float expertise_salinite;
    geometry forme_etoile;
    
    init {
        list<point> points_etoile <- [];
        loop i from: 0 to: 9 {
            float angle <- i * 36.0;
            float rayon <- (i mod 2 = 0) ? 1.5 : 0.6;
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
            
            float rendement_moyen <- mean(mes_parcelles collect each.rendement_saison);
            if rendement_moyen < 2.0 and strategie = "optimiste" {
                do declencher_transition("prudent", "formation_conseiller", rendement_moyen);
            }
        }
    }
    
    aspect default {
        draw forme_etoile color: #gold border: #black at: location;
    }
}


experiment Simulation_Rizieres type: gui {
    
    parameter "Nombre d'agriculteurs" var: nb_agriculteurs min: 10 max: 50 category: "Population";
    parameter "Nombre de parcelles" var: nb_parcelles min: 50 max: 200 category: "Population";
    parameter "Nombre de canaux" var: nb_canaux min: 3 max: 10 category: "Infrastructure";
    parameter "Seuil salinité critique (g/L)" var: seuil_salinite_critique min: 2.0 max: 8.0 category: "Environnement";
    parameter "Évaporation de base (mm/j)" var: evaporation_base min: 2.0 max: 10.0 category: "Environnement";
    parameter "Seuil faillite (M VND)" var: seuil_faillite min: 1.0 max: 10.0 category: "Économie" init: 5.0;
    parameter "Montant subvention (M VND)" var: montant_subvention min: 5.0 max: 20.0 category: "Économie" init: 10.0;
    parameter "Seuil subvention (M VND)" var: seuil_subvention min: 10.0 max: 30.0 category: "Économie" init: 15.0;
    
    output {
        
        display "Delta du Mékong - Rizières" type: 2d {
            grid zone_terre lines: #black;
            species parcelle aspect: default;
            species canal aspect: default;
            species agriculteur aspect: default;
            species capteur aspect: default;
            species conseiller aspect: default;
        }
        
        display "Évolution Salinité" refresh: every(1 #cycles) {
            chart "Salinité moyenne du delta" type: series {
                data "Salinité (g/L)" value: salinite_moyenne color: #red marker: false;
                data "Seuil critique" value: seuil_salinite_critique color: #orange marker: false;
            }
        }
        
        display "Rendements" refresh: every(10 #cycles) {
            chart "Production de riz" type: series {
                data "Rendement total (tonnes)" value: rendement_total color: #green marker: false;
            }
        }
        
        display "État des parcelles" refresh: every(1 #cycles) {
            chart "Parcelles dégradées par salinité" type: series {
                data "Nb parcelles dégradées" value: nb_parcelles_degradees color: #orange marker: false;
                data "Total parcelles" value: nb_parcelles color: #gray marker: false;
            }
        }
        
        display "Évolution des Stratégies" refresh: every(1 #cycles) {
            chart "Distribution des stratégies" type: series {
                data "Prudents" value: agriculteur count (each.strategie = "prudent") color: #blue marker: false;
                data "Suiveurs" value: agriculteur count (each.strategie = "suiveur") color: #yellow marker: false;
                data "Optimistes" value: agriculteur count (each.strategie = "optimiste") color: #red marker: false;
            }
        }
        
        display "Transitions" refresh: every(1 #cycles) {
            chart "Nombre de transitions" type: series {
                data "Total transitions" value: nb_transitions_total color: #purple marker: false;
                data "Vers prudent" value: nb_transitions_vers_prudent color: #blue marker: false;
                data "Vers optimiste" value: nb_transitions_vers_optimiste color: #red marker: false;
            }
        }
        
        // Graphiques économiques
        display "Économie" refresh: every(1 #cycles) {
            chart "Capital des agriculteurs" type: series {
                data "Capital total (M VND)" value: capital_total/1000000 color: #green marker: false;
                data "Capital moyen (M VND)" value: capital_moyen/1000000 color: #blue marker: false;
            }
        }
        
        display "Distribution Richesse" refresh: every(1 #cycles) {
            chart "Classes économiques" type: series {
                data "Pauvres (<15M)" value: nb_agriculteurs_pauvres color: #red marker: false;
                data "Riches (>30M)" value: nb_agriculteurs_riches color: #green marker: false;
            }
        }
        
        monitor "Jour de simulation" value: jour_simulation refresh: every(1 #cycles);
        monitor "Saison actuelle" value: saison = 1 ? "Sèche" : (saison = 2 ? "Pluies" : "Récolte") refresh: every(1 #cycles);
        monitor "Salinité moyenne (g/L)" value: salinite_moyenne with_precision 2 refresh: every(1 #cycles);
        monitor "Parcelles dégradées" value: nb_parcelles_degradees refresh: every(1 #cycles);
        monitor "% Parcelles dégradées" value: (nb_parcelles_degradees / nb_parcelles * 100) with_precision 1 refresh: every(1 #cycles);
        monitor "Rendement total (tonnes)" value: rendement_total with_precision 1 refresh: every(10 #cycles);
        monitor "Intensité marée" value: intensite_maree with_precision 2 refresh: every(1 #cycles);
        monitor "Pluie (mm/j)" value: niveau_pluie with_precision 1 refresh: every(1 #cycles);
        monitor "Température (°C)" value: temperature with_precision 1 refresh: every(1 #cycles);
        monitor "Transitions totales" value: nb_transitions_total refresh: every(1 #cycles);
        monitor "Nb Prudents" value: agriculteur count (each.strategie = "prudent") refresh: every(1 #cycles);
        monitor "Nb Suiveurs" value: agriculteur count (each.strategie = "suiveur") refresh: every(1 #cycles);
        monitor "Nb Optimistes" value: agriculteur count (each.strategie = "optimiste") refresh: every(1 #cycles);
        monitor "Nb agriculteurs actifs" value: length(list(agriculteur)) refresh: every(1 #cycles);
        monitor "Nb faillites" value: nb_faillites refresh: every(1 #cycles);
        monitor "Capital moyen (M VND)" value: capital_moyen/1000000 with_precision 1 refresh: every(1 #cycles);
        monitor "Agriculteurs pauvres" value: nb_agriculteurs_pauvres refresh: every(1 #cycles);
        monitor "Agriculteurs riches" value: nb_agriculteurs_riches refresh: every(1 #cycles);
    }
}
