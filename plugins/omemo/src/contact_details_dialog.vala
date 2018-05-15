using Gtk;
using Gee;
using Qlite;
using Dino.Entities;

namespace Dino.Plugins.Omemo {

[GtkTemplate (ui = "/im/dino/Dino/omemo/contact_details_dialog.ui")]
public class ContactDetailsDialog : Gtk.Dialog {

    private Plugin plugin;
    private Conversation conversation;

    [GtkChild] private Grid fingerprints;

    public ContactDetailsDialog(Plugin plugin, ArrayList<Row> devices) {
        Object(use_header_bar : 1);
        this.plugin = plugin;
        this.conversation = conversation;

        int i = 0;
        foreach (Row device in devices) {

            string res = fingerprint_markup(fingerprint_from_base64(device[plugin.db.identity_meta.identity_key_public_base64]));
            Label lbl = new Label(res) 
                { use_markup=true, justify=Justification.RIGHT, visible=true, margin = 8, halign = Alignment.START, valign = Alignment.CENTER };
            Switch tgl = new Switch() {visible = true, halign = Alignment.END, valign = Alignment.CENTER, margin = 8, hexpand = true };

            fingerprints.attach(lbl, 0, i);
            fingerprints.attach(tgl, 1, i);

            i++;

        }

    }

}

}
