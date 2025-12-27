#!/bin/bash

# Script to organize MP3s into instrument folders

cd /Users/ryanhelsing/Projects/neptunely_samples/MP3s

for file in *.mp3; do
    # Skip RTD and RTN files
    if [[ "$file" == *" RTD "* ]] || [[ "$file" == *" RTN "* ]]; then
        continue
    fi

    # Skip special pedal files that don't follow the pattern
    if [[ "$file" == *"Pedal Down.mp3" ]] || [[ "$file" == *"Pedal Up.mp3" ]]; then
        continue
    fi

    # Determine target folder based on mic config and articulation
    if [[ "$file" == "AT2035 XY Angle Dn PD "* ]]; then
        folder="../big_piano_at2035_xy_dn_pd"
        prefix="AT2035 XY Angle Dn PD "
    elif [[ "$file" == "AT2035 XY Angle Dn PU "* ]]; then
        folder="../big_piano_at2035_xy_dn_pu"
        prefix="AT2035 XY Angle Dn PU "
    elif [[ "$file" == "DM800 XY Angle Level PD "* ]]; then
        folder="../big_piano_dm800_xy_level_pd"
        prefix="DM800 XY Angle Level PD "
    elif [[ "$file" == "DM800 XY Angle Level PU "* ]]; then
        folder="../big_piano_dm800_xy_level_pu"
        prefix="DM800 XY Angle Level PU "
    elif [[ "$file" == "DM800 XY Angle Up PD "* ]]; then
        folder="../big_piano_dm800_xy_up_pd"
        prefix="DM800 XY Angle Up PD "
    elif [[ "$file" == "DM800 XY Angle Up PU "* ]]; then
        folder="../big_piano_dm800_xy_up_pu"
        prefix="DM800 XY Angle Up PU "
    elif [[ "$file" == "DM87 AB Front PD "* ]]; then
        folder="../big_piano_dm87_ab_front_pd"
        prefix="DM87 AB Front PD "
    elif [[ "$file" == "DM87 AB Front PU "* ]]; then
        folder="../big_piano_dm87_ab_front_pu"
        prefix="DM87 AB Front PU "
    elif [[ "$file" == "DM87 AB Rear PD "* ]]; then
        folder="../big_piano_dm87_ab_rear_pd"
        prefix="DM87 AB Rear PD "
    elif [[ "$file" == "DM87 AB Rear PU "* ]]; then
        folder="../big_piano_dm87_ab_rear_pu"
        prefix="DM87 AB Rear PU "
    elif [[ "$file" == "SE8 ORTF Hammers PD "* ]]; then
        folder="../big_piano_se8_ortf_hammers_pd"
        prefix="SE8 ORTF Hammers PD "
    elif [[ "$file" == "SE8 ORTF Hammers PU "* ]]; then
        folder="../big_piano_se8_ortf_hammers_pu"
        prefix="SE8 ORTF Hammers PU "
    else
        echo "Skipping unmatched: $file"
        continue
    fi

    # Extract the rest after prefix: "A0 0 23.mp3" or "C7 128 Plus.mp3"
    rest="${file#$prefix}"

    # Parse: NOTE VEL_START VEL_END.mp3
    # Handle special case "128 Plus"
    if [[ "$rest" == *" Plus.mp3" ]]; then
        # e.g., "C7 128 Plus.mp3"
        note=$(echo "$rest" | awk '{print $1}')
        vel_start=$(echo "$rest" | awk '{print $2}')
        vel_end="127"
    else
        # e.g., "A0 0 23.mp3"
        note=$(echo "$rest" | awk '{print $1}')
        vel_start=$(echo "$rest" | awk '{print $2}')
        vel_end=$(echo "$rest" | awk '{print $3}' | sed 's/.mp3//')
    fi

    # Convert note to lowercase and replace # with s (sharp)
    note_lower=$(echo "$note" | tr '[:upper:]' '[:lower:]' | sed 's/#/s/')

    # Build new filename
    new_name="${note_lower}_v${vel_start}-${vel_end}.mp3"

    # Copy file
    cp "$file" "$folder/$new_name"

done

echo "Done!"
