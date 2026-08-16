for mirror in "${!mirrors[@]}"; do
    printf "%s='%s'\n" "${mirror}" "${mirrors[${mirror}]}" >> $out
done
