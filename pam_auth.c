#include <security/pam_appl.h>
#include <security/pam_misc.h>
#include <stdio.h>
#include <string.h>

static struct pam_conv conv = {
    misc_conv,
    NULL
};

int main(int argc, char *argv[]) {
    pam_handle_t *pamh = NULL;
    int retval;
    const char *user = "root";

    retval = pam_start("login", user, &conv, &pamh);

    if (retval == PAM_SUCCESS)
        retval = pam_authenticate(pamh, 0);  // Demande le mot de passe

    if (retval == PAM_SUCCESS)
        retval = pam_acct_mgmt(pamh, 0);    // Vérifie que l'utilisateur est valide

    if (pam_end(pamh, retval) != PAM_SUCCESS) {
        fprintf(stderr, "Échec lors de la fermeture de la session PAM\n");
        return 1;
    }

    if (retval == PAM_SUCCESS) {
        printf("OK\n");
        return 0;
    } else {
        printf("Échec\n");
        return 1;
    }
}
