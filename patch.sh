#!/system/bin/sh

version=7.3.23

patch_smali() {
    DATA="    :cond_4
    const-string v0, \"recovery\"

    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_5

    :try_start_1
    # invokes: Lcom/android/internal/policy/impl/MiuiGlobalActions;->getPowerManager()Landroid/os/IPowerManager;
    invoke-static {}, Lcom/android/internal/policy/impl/MiuiGlobalActions;->access\$100()Landroid/os/IPowerManager;

    move-result-object v0

    const/4 v1, 0x0

    const-string v2, \"recovery\"

    const/4 v3, 0x0

    invoke-interface {v0, v1, v2, v3}, Landroid/os/IPowerManager;->reboot(ZLjava/lang/String;Z)V
    :try_end_1
    .catch Landroid/os/RemoteException; {:try_start_1 .. :try_end_1} :catch_1

    goto :goto_0

    :catch_1
    move-exception v0

    goto :goto_0

    :cond_5
    const-string v0, \"bootloader\"

    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-eqz v0, :cond_6

    :try_start_2
    # invokes: Lcom/android/internal/policy/impl/MiuiGlobalActions;->getPowerManager()Landroid/os/IPowerManager;
    invoke-static {}, Lcom/android/internal/policy/impl/MiuiGlobalActions;->access\$100()Landroid/os/IPowerManager;

    move-result-object v0

    const/4 v1, 0x0

    const-string v2, \"bootloader\"

    const/4 v3, 0x0

    invoke-interface {v0, v1, v2, v3}, Landroid/os/IPowerManager;->reboot(ZLjava/lang/String;Z)V
    :try_end_2
    .catch Landroid/os/RemoteException; {:try_start_2 .. :try_end_2} :catch_2

    goto :goto_0

    :catch_2
    move-exception v0

    goto :goto_0

    :cond_6"

    cp -f $SMALIFILE ${SMALIFILE}.bak

    awk -v r="$DATA" '{gsub(/    :cond_4/,r)}1' ${SMALIFILE}.bak > $SMALIFILE
}

patch_manifest_1() {
    sed -i "s|+#shutdown_dialog.visibility|+#shutdown_dialog.visibility+#recovery_dialog.visibility+#fastboot_dialog.visibility|" $MANIFESTFILE
}

patch_manifest_2() {
    DATA='            <VariableCommand name="shutdown_label_flag" expression="0" condition="#shutdown_dialog.visibility"/>
            <Command target="recovery_dialog.visibility" value="false" delay="600" condition="#recovery_dialog.visibility"/>
            <Command target="recovery_btn.visibility" value="true" delay="600" condition="#recovery_dialog.visibility"/>
            <VariableCommand name="recovery_label_flag" expression="0" condition="#recovery_dialog.visibility"/>
            <Command target="fastboot_dialog.visibility" value="false" delay="600" condition="#fastboot_dialog.visibility"/>
            <Command target="fastboot_btn.visibility" value="true" delay="600" condition="#fastboot_dialog.visibility"/>
            <VariableCommand name="fastboot_label_flag" expression="0" condition="#fastboot_dialog.visibility"/>'

    cp -f $MANIFESTFILE ${MANIFESTFILE}.bak

    awk -v r="$DATA" '{gsub(/            <VariableCommand name=\"shutdown_label_flag\" expression=\"0\" condition=\"#shutdown_dialog.visibility\"\/>/,r)}1' ${MANIFESTFILE}.bak > $MANIFESTFILE
}

patch_manifest_3() {
    sed -i 's|<Var name="uy" expression="#view_height/.*" />|<Var name="uy" expression="#view_height/2-400" />|' $MANIFESTFILE
}

patch_manifest_4() {
    DATA="    <Var name=\"dy\" expression=\"#view_height/2-40\" />
    <Var name=\"ny\" expression=\"#view_height/2+320\" />"

    cp -f $MANIFESTFILE ${MANIFESTFILE}.bak

    awk -v r="$DATA" '{gsub(/    <Var name=\"dy\" expression=\"#view_height\/2\+180\" \/>/,r)}1' ${MANIFESTFILE}.bak > $MANIFESTFILE
}

patch_manifest_5() {
    DATA='    <Var name="shutdown_label_flag" expression="1" const="true" />
    <Var name="recovery_label_flag" expression="1" const="true" />
    <Var name="fastboot_label_flag" expression="1" const="true" />'

    cp -f $MANIFESTFILE ${MANIFESTFILE}.bak

    awk -v r="$DATA" '{gsub(/    <Var name=\"shutdown_label_flag\" expression=\"1\" const=\"true\" \/>/,r)}1' ${MANIFESTFILE}.bak > $MANIFESTFILE
}

patch_manifest_6() {
    DATA='        <Text x="#rx" y="#dy+#label_space" color="#99ffffff" size="36" align="center" alignV="center" text="@label_shutdown" />
    </Group>
	<!-- recovery -->
    <Group name="recovery_btn" x="-#pos_offset_x*#ani_factor_inout" y="#pos_offset_y*#ani_factor_inout">
        <Button x="#lx-#circle_r" y="#ny-#circle_r" w="#btn_flag*#circle_r*2" h="#circle_r*2" contentDescriptionExp="@label_recovery">
            <Normal>
                <Circle x="#lx" y="#ny" r="#circle_r" strokeColor="#4cffffff" fillColor="#00ffffff" weight="2" strokeAlign="inner" />
            </Normal>
            <Pressed>
                <Circle x="#lx" y="#ny" r="#circle_r" strokeColor="#4cffffff" fillColor="#16ffffff" weight="2" strokeAlign="inner" />
            </Pressed>
            <Image x="#lx" y="#ny" align="center" alignV="center" src="recovery.png" />
            <Triggers>
                <Trigger action="down">
                    <Command target="blank_area.visibility" value="false" />
                </Trigger>
                <Trigger action="up,cancel">
                    <Command target="blank_area.visibility" value="true" />
                </Trigger>
                <Trigger action="up">
                    <VariableCommand name="btn_flag" expression="0" />
                    <VariableCommand name="dialog_btn_flag" expression="0"/>
                    <VariableCommand name="inout_flag" expression="0" />
                    <VariableCommand name="enter_flag" expression="1" />
                    <VariableCommand name="recovery_label_flag" expression="1"/>
                    <Command target="ani_timer_inout.animation" value="play" />
                    <Command target="ani_timer_enter.animation" value="play" />
                    <Command target="recovery_dialog.visibility" value="true" />
                    <Command target="recovery_btn.visibility" value="false" />
                </Trigger>
            </Triggers>
        </Button>
        <Text x="#lx" y="#ny+#label_space" color="#99ffffff" size="36" align="center" alignV="center" text="@label_recovery" />
    </Group>
	<!-- fastboot -->
    <Group name="fastboot_btn" x="#pos_offset_x*#ani_factor_inout" y="#pos_offset_y*#ani_factor_inout">
        <Button x="#rx-#circle_r" y="#ny-#circle_r" w="#btn_flag*#circle_r*2" h="#circle_r*2" contentDescriptionExp="@label_fastboot">
            <Normal>
                <Circle x="#rx" y="#ny" r="#circle_r" strokeColor="#4cffffff" fillColor="#00ffffff" weight="2" strokeAlign="inner" />
            </Normal>
            <Pressed>
                <Circle x="#rx" y="#ny" r="#circle_r" strokeColor="#4cffffff" fillColor="#16ffffff" weight="2" strokeAlign="inner" />
            </Pressed>
            <Image x="#rx" y="#ny" align="center" alignV="center" src="fastboot.png" />
            <Triggers>
                <Trigger action="down">
                    <Command target="blank_area.visibility" value="false" />
                </Trigger>
                <Trigger action="up,cancel">
                    <Command target="blank_area.visibility" value="true" />
                </Trigger>
                <Trigger action="up">
                    <VariableCommand name="btn_flag" expression="0" />
                    <VariableCommand name="dialog_btn_flag" expression="0"/>
                    <VariableCommand name="inout_flag" expression="0" />
                    <VariableCommand name="enter_flag" expression="1" />
                    <VariableCommand name="fastboot_label_flag" expression="1"/>
                    <Command target="ani_timer_inout.animation" value="play" />
                    <Command target="ani_timer_enter.animation" value="play" />
                    <Command target="fastboot_dialog.visibility" value="true" />
                    <Command target="fastboot_btn.visibility" value="false" />
                </Trigger>
            </Triggers>
        </Button>
        <Text x="#rx" y="#ny+#label_space" color="#99ffffff" size="36" align="center" alignV="center" text="@label_fastboot" />'

    cp -f $MANIFESTFILE ${MANIFESTFILE}.bak

    awk -v r="$DATA" '{gsub(/        <Text x=\"#rx\" y=\"#dy\+#label_space\" color=\"#99ffffff\" size=\"36\" align=\"center\" alignV=\"center\" text=\"@label_shutdown\" \/>/,r)}1' ${MANIFESTFILE}.bak > $MANIFESTFILE
}

patch_manifest_7() {
    DATA='        <Text name="shutdown_label" x="#view_width/2" y="#view_height-100" w="#view_width-20" multiLine="true" color="#80ffffff" size="36" alpha="255*(1-#ani_factor_enter)" alignH="center" alignV="bottom" textExp="@shutdown_info" />
    </Group>
	<!-- recovery alert dialog -->
    <Group name="recovery_dialog" visibility="false">
        <Button x="#view_width/2-#big_circle_r+(#lx-#view_width/2)*#ani_factor_enter" y="#confirm_y-#big_circle_r+(#ny-#confirm_y)*#ani_factor_enter" w="lt(#ani_factor_enter,0.2)*#big_circle_r*2" h="#big_circle_r*2" contentDescriptionExp="@label_alert_recovery">
            <Normal>
                <Circle x="#view_width/2+(#lx-#view_width/2)*#ani_factor_enter" y="#confirm_y+(#ny-#confirm_y)*#ani_factor_enter" r="#big_circle_r" scale="(1-0.29*#ani_factor_enter)*#ani_gone_dialogicon" strokeColor="#4cffffff" fillColor="#00ffffff" weight="2" strokeAlign="inner" />
            </Normal>
            <Pressed>
                <Circle x="#view_width/2+(#lx-#view_width/2)*#ani_factor_enter" y="#confirm_y+(#ny-#confirm_y)*#ani_factor_enter" r="#big_circle_r" scale="(1-0.29*#ani_factor_enter)*#ani_gone_dialogicon" strokeColor="#4cffffff" fillColor="#16ffffff" weight="2" strokeAlign="inner" />
            </Pressed>
            <Image name="recovery_big" x="#view_width/2+(#lx-#view_width/2)*#ani_factor_enter" y="#confirm_y+(#ny-#confirm_y)*#ani_factor_enter" align="center" alignV="center" pivotX="#recovery_big.bmp_width/2" pivotY="#recovery_big.bmp_height/2" scale="(1-0.2523*#ani_factor_enter)*#ani_gone_dialogicon" src="recovery_big.png" loadSync="true"/>
            <Triggers>
                <Trigger action="down">
                    <Command target="blank_area.visibility" value="false" />
                </Trigger>
                <Trigger action="up,cancel">
                    <Command target="blank_area.visibility" value="true" />
                </Trigger>
                <Trigger action="up">
                    <VariableCommand name="dialog_btn_flag" expression="0" />
                    <Command target="ani_gone_dialogicon.animation" value="play" />
                    <Command target="ani_gone_dialogtext.animation" value="play" delay="100" />
                    <Command target="ani_gone_dialogcancel.animation" value="play" delay="200" />
                    <ExternCommand command="dismiss" delay="700" />
                    <ExternCommand command="recovery" delay="700" />  <!-- TODO 700- to make sure reboot can be received -->
                </Trigger>
            </Triggers>
        </Button>
        <Text name="recovery_confirm_label" x="#view_width/2+(#lx-#view_width/2)*#ani_factor_enter" y="#confirm_label_y+(#ny+#label_space-#confirm_label_y)*#ani_factor_enter" color="#99ffffff" size="40" pivotX="#recovery_confirm_label.text_width/2" pivotY="#recovery_confirm_label.text_height/2" scale="(1-0.11*#ani_factor_enter)*#ani_gone_dialogtext" align="center" alignV="center" textExp="ifelse(#recovery_label_flag,@label_alert_recovery,@label_recovery)" />
    </Group>
	<!-- fastboot alert dialog -->
    <Group name="fastboot_dialog" visibility="false">
        <Button x="#view_width/2-#big_circle_r+(#rx-#view_width/2)*#ani_factor_enter" y="#confirm_y-#big_circle_r+(#ny-#confirm_y)*#ani_factor_enter" w="lt(#ani_factor_enter,0.2)*#big_circle_r*2" h="#big_circle_r*2" contentDescriptionExp="@label_alert_fastboot">
            <Normal>
                <Circle x="#view_width/2+(#rx-#view_width/2)*#ani_factor_enter" y="#confirm_y+(#ny-#confirm_y)*#ani_factor_enter" r="#big_circle_r" scale="(1-0.29*#ani_factor_enter)*#ani_gone_dialogicon" strokeColor="#4cffffff" fillColor="#00ffffff" weight="2" strokeAlign="inner" />
            </Normal>
            <Pressed>
                <Circle x="#view_width/2+(#rx-#view_width/2)*#ani_factor_enter" y="#confirm_y+(#ny-#confirm_y)*#ani_factor_enter" r="#big_circle_r" scale="(1-0.29*#ani_factor_enter)*#ani_gone_dialogicon" strokeColor="#4cffffff" fillColor="#16ffffff" weight="2" strokeAlign="inner" />
            </Pressed>
            <Image name="fastboot_big" x="#view_width/2+(#rx-#view_width/2)*#ani_factor_enter" y="#confirm_y+(#ny-#confirm_y)*#ani_factor_enter" align="center" alignV="center" pivotX="#fastboot_big.bmp_width/2" pivotY="#fastboot_big.bmp_height/2" scale="(1-0.2743*#ani_factor_enter)*#ani_gone_dialogicon" src="fastboot_big.png" loadSync="true"/>
            <Triggers>
                <Trigger action="down">
                    <Command target="blank_area.visibility" value="false" />
                </Trigger>
                <Trigger action="up,cancel">
                    <Command target="blank_area.visibility" value="true" />
                </Trigger>
                <Trigger action="up">
                    <VariableCommand name="dialog_btn_flag" expression="0" />
                    <Command target="ani_gone_dialogicon.animation" value="play" />
                    <Command target="ani_gone_dialogtext.animation" value="play" delay="100" />
                    <Command target="ani_gone_dialogcancel.animation" value="play" delay="200" />
                    <ExternCommand command="dismiss" delay="700" />
                    <ExternCommand command="fastboot" delay="700" />
                </Trigger>
            </Triggers>
        </Button>
        <Text name="fastboot_confirm_label" x="#view_width/2+(#rx-#view_width/2)*#ani_factor_enter" y="#confirm_label_y+(#ny+#label_space-#confirm_label_y)*#ani_factor_enter" color="#99ffffff" size="40" pivotX="#fastboot_confirm_label.text_width/2" pivotY="#fastboot_confirm_label.text_height/2" scale="(1-0.11*#ani_factor_enter)*#ani_gone_dialogtext" align="center" alignV="center" textExp="ifelse(#fastboot_label_flag,@label_alert_fastboot,@label_fastboot)" />'

    cp -f $MANIFESTFILE ${MANIFESTFILE}.bak

    awk -v r="$DATA" '{gsub(/        <Text name=\"shutdown_label\" x=\"#view_width\/2\" y=\"#view_height\-100\" w=\"#view_width\-20\" multiLine=\"true\" color=\"#80ffffff\" size=\"36\" alpha=\"255\*\(1\-#ani_factor_enter\)\" alignH=\"center\" alignV=\"bottom\" textExp=\"@shutdown_info\" \/>/,r)}1' ${MANIFESTFILE}.bak > $MANIFESTFILE
}

patch_strings() {
    STRINGSFILE=$PATCHDIR/powermenu.out/strings/strings$1.xml

    DATA="    <string name=\"label_shutdown\">$2</string>
    <string name=\"label_recovery\">Recovery</string>
    <string name=\"label_fastboot\">Fastboot</string>"

    cp -f $STRINGSFILE ${STRINGSFILE}.bak

    awk -v r="$DATA" "{gsub(/    <string name=\"label_shutdown\">$2<\/string>/,r)}1" ${STRINGSFILE}.bak > $STRINGSFILE

    DATA="    <string name=\"label_alert_shutdown\">$3</string>
    <string name=\"label_alert_recovery\">$4</string>
    <string name=\"label_alert_fastboot\">$5</string>"

    cp -f $STRINGSFILE ${STRINGSFILE}.bak

    awk -v r="$DATA" "{gsub(/    <string name=\"label_alert_shutdown\">$3<\/string>/,r)}1" ${STRINGSFILE}.bak > $STRINGSFILE

    rm -f ${STRINGSFILE}.bak
}
