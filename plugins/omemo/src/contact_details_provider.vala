using Gtk;
using Gee;
using Qlite;
using Dino.Entities;

namespace Dino.Plugins.Omemo {

public class ContactDetailsProvider : Plugins.ContactDetailsProvider, Object {
    public string id { get { return "omemo_info"; } }

    private Plugin plugin;
    private Button btn;

    public ContactDetailsProvider(Plugin plugin) {
        this.plugin = plugin;
    }

    public void populate(Conversation conversation, Plugins.ContactDetails contact_details, WidgetType type) {
        if (conversation.type_ == Conversation.Type.CHAT && type == WidgetType.GTK) {

            ArrayList<Row> devices = new ArrayList<Row> ();

            foreach (Row row in plugin.db.identity_meta.with_address(conversation.counterpart.to_string())) {
                if (row[plugin.db.identity_meta.identity_key_public_base64] != null) {
                    devices.add(row);
                }
            }

            if (devices.size > 0) {
                Button btn = new Button();
                btn.image = new Image.from_icon_name("view-list-symbolic", IconSize.BUTTON);
                btn.relief = ReliefStyle.NONE;
                btn.visible = true;
                btn.valign = Align.CENTER;
                btn.clicked.connect(() => {
                    btn.activate();
                    ContactDetailsDialog dialog = new ContactDetailsDialog(plugin, devices);
                    dialog.set_transient_for((Window) btn.get_toplevel());
                    dialog.present();
                });

                contact_details.add(_("Encryption"), "OMEMO", n("%d OMEMO device", "%d OMEMO devices", devices.size).printf(devices.size), btn);
            }
        }
    }
}

}
