#!/bin/bash

# Fonction pour mettre la première lettre en majuscule
capitalize_first() {
    echo "$1" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}'
}

# Fonction pour convertir en majuscules
uppercase() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

# Fonction pour valider un mot de passe selon les règles classiques AD
validate_password() {
    local password="$1"
    if [[ ${#password} -lt 8 ]]; then
        return 1
    fi
    if ! [[ "$password" =~ [A-Z] ]]; then
        return 1
    fi
    if ! [[ "$password" =~ [a-z] ]]; then
        return 1
    fi
    if ! [[ "$password" =~ [0-9] ]]; then
        return 1
    fi
    if ! [[ "$password" =~ [^a-zA-Z0-9] ]]; then
        return 1
    fi
    return 0
}

# Fonction pour lister les utilisateurs et sélectionner
select_user() {
    mapfile -t users < <(samba-tool user list | sort)
    while true; do
        clear
        echo -e "Liste des utilisateurs :"
        for i in "${!users[@]}"; do
            echo "$((i+1)) - ${users[$i]}"
        done
        echo
        echo "0 - Retour au menu principal"
        echo
        echo -ne "Entrez le numéro de l'utilisateur : "
        read -r index

        if [[ "$index" == "0" ]]; then
            # Réinitialisation des variables
            selected_user=""
            prenom=""
            nom=""
            description=""
            ou=""
            return 1
        elif [[ "$index" =~ ^[0-9]+$ ]] && (( index >= 1 && index <= ${#users[@]} )); then
            selected_user="${users[$((index-1))]}"

            user_info=$(samba-tool user show "$selected_user")
            prenom=$(echo "$user_info" | grep -i 'givenName:' | awk -F': ' '{print $2}')
            nom=$(echo "$user_info" | grep -i 'sn:' | awk -F': ' '{print $2}')
            description=$(echo "$user_info" | grep -i 'description:' | awk -F': ' '{print $2}')
	    dn_line=$(echo "$user_info" | grep -i '^dn:')
	    ou="${dn_line#dn: }"

            return 0
        else
            echo
            echo -e "❌ Entrée invalide, veuillez réessayer"
            sleep 2
        fi
    done
}

# Fonction authentification root
authentifier_root() {
    echo "🔐 Veuillez entrer le mot de passe root pour continuer"
    echo
    ./pam_auth
    if [[ $? -ne 0 ]]; then
        echo "❌ Mot de passe incorrect. Opération annulée"
        clear
	return 1
    fi
    return 0
}

# Authentification avant accès au menu
clear
echo "╔════════════════════════════════════════════════════╗"
echo "║ 🔐  Authentification requise pour accéder au menu  ║"
echo "╚════════════════════════════════════════════════════╝"
echo

if ! authentifier_root; then
#    echo
#    echo "❌ Échec de l'authentification root"
#    echo "🚫 Accès refusé. Fermeture du script..."
#    echo
    sleep 2
    exit 1
else
    echo
    echo "✅ Authentification réussie"
    sleep 2
fi

# Menu
while true; do
clear
echo
    echo "==== Menu de gestion Samba AD ===="
    echo
    echo "1 - Créer un utilisateur"
    echo "2 - Supprimer un utilisateur"
    echo "3 - Réinitialiser le mot de passe d'un utilisateur"
    echo "4 - Désactiver un utilisateur"
    echo "5 - Activer un utilisateur"
    echo "6 - Ajouter un utilisateur à un groupe"
    echo "7 - Afficher les détails d'un utilisateur"
echo
    echo "0 - Quitter"
echo
    echo -n "Choix : "
    read -r choice

    if ! [[ "$choice" =~ ^[0-7]$ ]]; then
echo
        echo -e "❌ Veuillez saisir une option valide"
        sleep 2
        continue
    fi

    case $choice in

# Créer un utilisateur
1)
clear
echo
            echo -n "Prénom : "
            read -r prenom
            echo -n "Nom : "
            read -r nom

            prenom_formate=$(capitalize_first "$prenom")
            nom_formate=$(uppercase "$nom")
            identifiant=$(echo "${prenom:0:1}.$nom" | tr '[:upper:]' '[:lower:]')
            description="$prenom_formate $nom_formate"

            # Vérifier si l'utilisateur existe déjà
            if samba-tool user show "$identifiant" &>/dev/null; then
clear
echo
                echo "❌ L'utilisateur '$identifiant' existe déjà, merci de recommencer"
echo
continue
            fi

            while true; do
                echo -n "Mot de passe : "
                read -rs mdp
                echo ""
                validate_password "$mdp"
                if [[ $? -eq 0 ]]; then
                    break

                else
                    echo "❌ Le mot de passe doit contenir au moins :"
                    echo "- 8 caractères"
                    echo "- 1 majuscule, 1 minuscule, 1 chiffre, 1 caractère spécial"
                    echo "Tapez 0 pour annuler la création ou appuyez sur Entrée pour réessayer"
                    read -r cancel
                    [[ "$cancel" == "0" ]] && continue 2
                fi
            done

	    samba-tool user create "$identifiant" "$mdp" \
 	    --given-name="$prenom_formate" \
	    --surname="$nom_formate" \
 	    --description="$description" \
 	    --must-change-at-next-login

clear
echo
            echo "✅ Utilisateur $description créé avec l'identifiant : $identifiant"
echo
read -rp "Appuyez sur Entrée pour revenir au menu..."
continue
            ;;

# Supprimer un utilisateur
2)
            if select_user; then
                samba-tool user delete "$selected_user"
                clear
                echo
                echo "✅ Utilisateur $description ($selected_user) supprimé"
                echo
                read -rp "Appuyez sur Entrée pour revenir au menu..."
            else
                echo
		continue
            fi
            ;;

# Réinitialiser le mot de passe d'un utilisateur
3)
    if select_user; then
        while true; do
            echo -n "Nouveau mot de passe : "
            read -rs mdp
            echo
            echo -n "Confirmez le mot de passe : "
            read -rs mdp_confirm
            echo

            if [[ "$mdp" != "$mdp_confirm" ]]; then
                echo "❌ Les mots de passe ne correspondent pas"
                echo "Tapez 0 pour annuler ou appuyez sur Entrée pour réessayer"
                read -r cancel
                if [[ "$cancel" == "0" ]]; then
                    echo -e "↩️  Retour au menu principal"
                    sleep 1
                    continue 2
                else
                    continue
                fi
            fi

            validate_password "$mdp"
            if [[ $? -eq 0 ]]; then
                break
            else
                echo "❌ Mot de passe invalide"
                echo "Tapez 0 pour annuler ou appuyez sur Entrée pour réessayer"
                read -r cancel
                if [[ "$cancel" == "0" ]]; then
                    echo -e "↩️  Retour au menu principal"
                    sleep 1
                    continue 2
                fi
            fi
        done

        samba-tool user setpassword "$selected_user" --newpassword="$mdp" --quiet
        clear
        echo
        echo "✅ Mot de passe modifié pour $description ($selected_user)"
        echo
        read -rp "Appuyez sur Entrée pour revenir au menu..."
    else
        continue
    fi
    ;;

# Désactiver un utilisateur
4)
            if select_user; then
                samba-tool user disable "$selected_user"
                clear
                echo
                echo "✅ Utilisateur désactivé : $description ($selected_user)"
                echo
                read -rp "Appuyez sur Entrée pour revenir au menu..."
            else
                continue
            fi
            ;;

# Activer un utilisateur
5)
            if select_user; then
                samba-tool user enable "$selected_user"
                clear
                echo
                echo "✅ Utilisateur activé : $description ($selected_user)"
                echo
                read -rp "Appuyez sur Entrée pour revenir au menu..."
            else
                continue
            fi
            ;;

# Ajouter un utilisateur à un groupe
6)
	    if select_user; then
	        # Récupération et tri des groupes
	        mapfile -t groups < <(samba-tool group list | sort)
	        while true; do
	            clear
	            echo -e "Liste des groupes :"
	            for i in "${!groups[@]}"; do
	                echo "$((i+1)) - ${groups[$i]}"
	            done
	            echo
	            echo "0 - Annuler et revenir au menu principal"
	            echo -ne "Entrez le numéro du groupe : "
	            read -r group_index

	            if [[ "$group_index" == "0" ]]; then
	                break
	            elif [[ "$group_index" =~ ^[0-9]+$ ]] && (( group_index >= 1 && group_index <= ${#groups[@]} )); then
	                group_selected="${groups[$((group_index-1))]}"
	                samba-tool group addmembers "$group_selected" "$selected_user"
	                clear
	                echo
	                echo "✅ $selected_user ($prenom $nom - $description) ajouté au groupe $group_selected"
	                echo
	                read -rp "Appuyez sur Entrée pour revenir au menu..."
	                break
	            else
	                echo -e "❌ Entrée invalide, veuillez saisir un numéro valide"
	                sleep 2
	            fi
	        done
	    else
	        continue
	    fi
	    ;;

# Afficher les détails d'un utilisateur
7)
    if select_user; then
        clear
        echo -e "🔍 Informations détaillées pour $prenom $nom ($selected_user) :"

        user_info=$(samba-tool user show "$selected_user")

        # Extraction des champs utiles
        sn=$(echo "$user_info" | grep -i '^sn:' | awk -F': ' '{print $2}')
        description=$(echo "$user_info" | grep -i '^description:' | awk -F': ' '{print $2}')
        givenName=$(echo "$user_info" | grep -i '^givenName:' | awk -F': ' '{print $2}')
        whenCreatedRaw=$(echo "$user_info" | grep -i '^whenCreated:' | awk -F': ' '{print $2}')
        lastLogon=$(echo "$user_info" | grep -i '^lastLogon:' | awk -F': ' '{print $2}')
        logonCount=$(echo "$user_info" | grep -i '^logonCount:' | awk -F': ' '{print $2}')
        sAMAccountName=$(echo "$user_info" | grep -i '^sAMAccountName:' | awk -F': ' '{print $2}')
        userPrincipalName=$(echo "$user_info" | grep -i '^userPrincipalName:' | awk -F': ' '{print $2}')
        userAccountControl=$(echo "$user_info" | grep -i '^userAccountControl:' | awk -F': ' '{print $2}')
        dn_line=$(echo "$user_info" | grep -i '^dn:')
        ou="${dn_line#dn: }"

        # Formatage simple de la date whenCreated → JJ/MM/AAAA
        jour=${whenCreatedRaw:6:2}
        mois=${whenCreatedRaw:4:2}
        annee=${whenCreatedRaw:0:4}
        whenCreatedFormatted="$jour/$mois/$annee"

        # Interprétation du statut du compte
        if [[ "$userAccountControl" == "514" ]]; then
            statut="❌ Désactivé"
        else
            statut="✅ Activé"
        fi

        echo -e "👤 Nom complet            : $givenName $sn"
        echo -e "🆔 Identifiant            : $sAMAccountName"
        echo -e "📛 Description            : $description"
        echo -e "📂 Emplacement (OU)       : $ou"
        echo -e "📨 Adresse de connexion   : $userPrincipalName"
        echo -e "📅 Créé le                : $whenCreatedFormatted"
        echo -e "🔓 Dernière connexion     : $lastLogon"
        echo -e "🔁 Nombre de connexions   : $logonCount"
        echo -e "🔒 Statut du compte       : $statut"
        echo
        read -rp "Appuyez sur Entrée pour revenir au menu..."
    else
        continue
    fi
    ;;

        0)
clear
            exit 0
            ;;

        *)
            echo "❌ Choix invalide, réessayez"
            ;;
    esac

done
