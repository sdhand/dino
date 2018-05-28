using Dino.Entities;
using Xmpp;
using Gtk;

namespace Dino.Plugins.Omemo {

public class DeviceNotificationPopulator : ConversationItemPopulator, Object {

    public string id { get { return "device_notification"; } }

    private StreamInteractor? stream_interactor;
    private Plugin plugin;
    private Conversation? current_conversation;
    private ConversationItemCollection? item_collection;

    public DeviceNotificationPopulator(Plugin plugin, StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        this.plugin = plugin;
    }

    public bool has_new_devices(Jid jid) {
        return plugin.db.identity_meta.with_address(jid.bare_jid.to_string()).with(plugin.db.identity_meta.requires_trust_decision, "=", true).count() > 0;
    }

    public void init(Conversation conversation, ConversationItemCollection item_collection, Plugins.WidgetType type) {
        current_conversation = conversation;
        this.item_collection = item_collection;
        stream_interactor.module_manager.get_module(conversation.account, StreamModule.IDENTITY).device_list_loaded.connect((jid) => {
                if(jid == conversation.counterpart && has_new_devices(conversation.counterpart) && conversation.type_ == Conversation.Type.CHAT)
                    display_notification();
            });
        if (has_new_devices(conversation.counterpart) && conversation.type_ == Conversation.Type.CHAT)
                display_notification();
    }

    public void close(Conversation conversation) { }

    public void populate_timestamp(Conversation conversation, DateTime from, DateTime to) { }

    public void populate_between_widgets(Conversation conversation, DateTime from, DateTime to) { }

    private void display_notification() {
        //stdout.printf("Displaying notification: %s\n", current_conversation.counterpart.localpart);
        item_collection.add_meta_notification(new ConversationNotification(plugin, current_conversation.counterpart));
    }
}

private class ConversationNotification : MetaConversationNotification { 
    private Widget widget;

    public ConversationNotification(Plugin plugin, Jid jid) {
        Box box = new Box(Orientation.HORIZONTAL, 5) { visible=true };
        Button manage_button = new Button() { label=_("Manage"), visible=true };
        manage_button.clicked.connect(() => {
            manage_button.activate();
            ContactDetailsDialog dialog = new ContactDetailsDialog(plugin, jid);
            dialog.set_transient_for((Window) manage_button.get_toplevel());
            dialog.present();
        });
        box.add(new Label(_("This contact has new devices")) { margin_end=10, visible=true });
        box.add(manage_button);
        widget = box;
    }

    public override Object? get_widget(WidgetType type) {
        return widget;
    }
}

}
