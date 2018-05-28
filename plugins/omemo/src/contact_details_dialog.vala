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

    public ContactDetailsDialog(Plugin plugin, Jid jid) {
        Object(use_header_bar : 1);
        this.plugin = plugin;

        int i = 0;
        foreach (Row device in plugin.db.identity_meta.with_address(jid.to_string())) {
            if(device[plugin.db.identity_meta.identity_key_public_base64] == null)
                continue;

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

            fingerprints.attach(lbl, 0, i);
            fingerprints.attach(tgl, 1, i);

            i++;

        }

    }

}

}
