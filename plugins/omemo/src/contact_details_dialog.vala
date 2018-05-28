using Gtk;
using Xmpp;
using Gee;
using Qlite;
using Dino.Entities;

namespace Dino.Plugins.Omemo {

[GtkTemplate (ui = "/im/dino/Dino/omemo/contact_details_dialog.ui")]
public class ContactDetailsDialog : Gtk.Dialog {

    private Plugin plugin;

    [GtkChild] private Grid fingerprints;
    [GtkChild] private Box fingerprints_prompt_label;
    [GtkChild] private Frame fingerprints_prompt_container;
    [GtkChild] private Grid fingerprints_prompt;

    private void add_fingerprint(Row device, int row) {
        string res = fingerprint_markup(fingerprint_from_base64(device[plugin.db.identity_meta.identity_key_public_base64]));
        Label lbl = new Label(res)
            { use_markup=true, justify=Justification.RIGHT, visible=true, margin = 8, halign = Align.START, valign = Align.CENTER };
        Switch tgl = new Switch() {visible = true, halign = Align.END, valign = Align.CENTER, margin = 8, hexpand = true, active = device[plugin.db.identity_meta.trusted_identity] };
        tgl.state_set.connect((active) => {
            plugin.db.identity_meta.update()
                .with(plugin.db.identity_meta.device_id, "=", device[plugin.db.identity_meta.device_id])
                .set(plugin.db.identity_meta.trusted_identity, active).perform();

            return false;
        });

        fingerprints.attach(lbl, 0, row);
        fingerprints.attach(tgl, 1, row);
    }

    public ContactDetailsDialog(Plugin plugin, Jid jid) {
        Object(use_header_bar : 1);
        this.plugin = plugin;

        int i = 0;
        foreach (Row device in plugin.db.identity_meta.with_address(jid.to_string()).with(plugin.db.identity_meta.requires_trust_decision, "=", false)) {
            if(device[plugin.db.identity_meta.identity_key_public_base64] == null)
                continue;
            add_fingerprint(device, i);

            i++;

        }

        int j = 0;
        foreach (Row device in plugin.db.identity_meta.with_address(jid.to_string()).with(plugin.db.identity_meta.requires_trust_decision, "=", true)) {
            if(device[plugin.db.identity_meta.identity_key_public_base64] == null)
                continue;

            string res = fingerprint_markup(fingerprint_from_base64(device[plugin.db.identity_meta.identity_key_public_base64]));
            Label lbl = new Label(res)
                { use_markup=true, justify=Justification.RIGHT, visible=true, margin = 8, halign = Align.START };

            Box box = new Box(Gtk.Orientation.HORIZONTAL, 0) { visible = true, valign = Align.CENTER, hexpand = true, margin = 8 };

            Button yes = new Button() { visible = true, valign = Align.CENTER, hexpand = true};
            yes.image = new Image.from_icon_name("list-add-symbolic", IconSize.BUTTON);

            yes.clicked.connect(() => {
                plugin.db.identity_meta.update()
                    .with(plugin.db.identity_meta.device_id, "=", device[plugin.db.identity_meta.device_id])
                    .set(plugin.db.identity_meta.trusted_identity, true)
                    .set(plugin.db.identity_meta.requires_trust_decision, false)
                    .perform();
                 fingerprints_prompt.remove(box);
                 fingerprints_prompt.remove(lbl);
                 j--;

                 add_fingerprint(device, i);
                 i++;

                 if(j == 0)
                    fingerprints_prompt.attach(new Label("No more new devices") { visible = true, valign = Align.CENTER, halign = Align.CENTER, margin = 8, hexpand = true }, 0, 0);
            });

            Button no = new Button() { visible = true, valign = Align.CENTER, hexpand = true};
            no.image = new Image.from_icon_name("list-remove-symbolic", IconSize.BUTTON);

            no.clicked.connect(() => {
                plugin.db.identity_meta.update()
                    .with(plugin.db.identity_meta.device_id, "=", device[plugin.db.identity_meta.device_id])
                    .set(plugin.db.identity_meta.trusted_identity, false)
                    .set(plugin.db.identity_meta.requires_trust_decision, false)
                    .perform();
                fingerprints_prompt.remove(box);
                fingerprints_prompt.remove(lbl);
                j--;

                add_fingerprint(device, i);
                i++;

                if(j == 0)
                    fingerprints_prompt.attach(new Label("No more new devices") { visible = true, valign = Align.CENTER, halign = Align.CENTER, margin = 8, hexpand = true }, 0, 0);
            });

            box.pack_start(yes);
            box.pack_start(no);

            box.get_style_context().add_class("linked");

            fingerprints_prompt.attach(lbl, 0, j);
            fingerprints_prompt.attach(box, 1, j);
            j++;
        }
        if( j > 0 ){
            fingerprints_prompt_label.visible = true;
            fingerprints_prompt_container.visible = true;
        }

    }

}

}
