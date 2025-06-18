Script d'administration pour Samba Active Directory  

Ce script interactif permet de gérer facilement les comptes utilisateurs dans un domaine Samba AD via l’outil "samba-tool".  
Il propose un menu simple pour effectuer les opérations les plus courantes :  

✅ Création d’utilisateurs avec vérification du mot de passe  
✅ Suppression de comptes  
✅ Réinitialisation des mots de passe  
✅ Activation / désactivation d’utilisateurs  
✅ Ajout d’un utilisateur à un groupe  
✅ Consultation des informations détaillées d’un utilisateur  

Fonctionnalités supplémentaires :  
- Génération automatique d’identifiants ("prenom.nom")  
- Capitalisation automatique des prénoms et noms  
- Validation stricte du mot de passe (longueur, majuscules, chiffres, caractères spéciaux)  
- Interface en ligne de commande claire et lisible  

Requis :  
- Le serveur doit être contrôleur de domaine Samba AD  
- Le paquet "samba-tool" doit être installé et fonctionnel

Utilisation typique :  

- Installation des dépendences pour "pam-authenticate" : apt install gcc libpam0g-dev -y
- Compilation du script "pam_auth.c" : gcc pam_auth.c -o pam_auth -lpam -lpam_misc
- Rendre le scripts "pam_auth" exécutable uniquement par root : chmod 700 pam_auth && chown root:root pam_auth
- Rendre le script "SambaAD.sh" exécutable uniquement par root : chmod 700 SambaAD.sh && chown root:root pam_auth
- Lancement du script sur la machine Samba AD : ./SambaAD.sh    

Création :  
PhOeNiX  
Web Site : S3curity.info  
YouTube : PhOeNiX v8.3  
