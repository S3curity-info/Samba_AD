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
 
- Rendre le script exécutable : chmod u+x SambaAD.sh  
- Lancer ce script sur la machine Samba AD : ./SambaAD.sh    

Création :  
PhOeNiX  
Web Site : S3curity.info  
YouTube : PhOeNiX v8.3  
