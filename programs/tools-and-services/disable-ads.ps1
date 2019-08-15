#--- Ad blocking with hosts file ---
$hfile = "$env:windir\System32\drivers\etc\hosts"
function Block-Ad {
    Param ($domain)
    if (!(Select-String -Path "$hfile" -Pattern "$domain" -SimpleMatch -Quiet)) {
        # Doesn't already exist so lets add it
        $out = ''
        if ($domain -like '* *') {
            # add as-is because it's a ip and domain pair
            $out = $domain
        }
        else {
            # route to 0.0.0.0
            $out = "0.0.0.0    $domain"
        }
        "$out" | Add-Content -PassThru "$hfile"
        Return 0
    }
    Return -1
}

Block-Ad 'pubads.g.doubleclick.net'
Block-Ad 'securepubads.g.doubleclick.net'
Block-Ad 'www.googletagservices.com'
Block-Ad 'gads.pubmatic.com'
Block-Ad 'ads.pubmatic.com'
Block-Ad 'spclient.wg.spotify.com'