using Dino.Entities;
using Xmpp;
using Gtk;

namespace Dino.Plugins.Omemo {

public class DeviceNotificationPopulator : NotificationPopulator, Object {

    public string id { get { return "device_notification"; } }

    private StreamInteractor? stream_interactor;
    private Plugin plugin;
    private Conversation? current_conversation;
    private NotificationCollection? notification_collection;
    private ConversationNotification notification;

    public DeviceNotificationPopulator(Plugin plugin, StreamInteractor stream_interactor) {
        this.stream_interactor = stream_interactor;
        this.plugin = plugin;
    }

    public bool has_new_devices(Jid jid) {
        return plugin.db.identity_meta.with_address(current_conversation.account.id, jid.bare_jid.to_string()).with(plugin.db.identity_meta.trusted_identity, "=", Database.IdentityMetaTable.TrustLevel.UNKNOWN).without_null(plugin.db.identity_meta.identity_key_public_base64).count() > 0;
    }

    public void init(Conversation conversation, NotificationCollection notification_collection, Plugins.WidgetType type) {
        current_conversation = conversation;
        this.notification_collection = notification_collection;
        stream_interactor.module_manager.get_module(conversation.account, StreamModule.IDENTITY).device_list_loaded.connect((jid) => {
                if (jid == conversation.counterpart && has_new_devices(conversation.counterpart) && conversation.type_ == Conversation.Type.CHAT) {
                    display_notification();
                }
            });
        if (has_new_devices(conversation.counterpart) && conversation.type_ == Conversation.Type.CHAT) {
            display_notification();
        }
    }

    public void close(Conversation conversation) {
        notification = null;
    }

    private void display_notification() {
        if(notification == null) {
            notification = new ConversationNotification(plugin, current_conversation.account, current_conversation.counterpart);
            notification.should_hide.connect(should_hide);
            notification_collection.add_meta_notification(notification);
        }
    }

    public void should_hide() {
        if (!has_new_devices(current_conversation.counterpart) && notification != null){
            notification_collection.remove_meta_notification(notification);
            notification = null;
        }
    }
}

private class ConversationNotification : MetaConversationNotification {
    private Widget widget;
    private Plugin plugin;
    private Jid jid;
    private Account account;
    public signal void should_hide();

    public ConversationNotification(Plugin plugin, Account account, Jid jid) {
        this.plugin = plugin;
        this.jid = jid;
        this.account = account;

        Box box = new Box(Orientation.HORIZONTAL, 5) { visible=true };
        Button manage_button = new Button() { label=_("Manage"), visible=true };
        manage_button.clicked.connect(() => {
            manage_button.activate();
            ContactDetailsDialog dialog = new ContactDetailsDialog(plugin, account, jid);
            dialog.set_transient_for((Window) manage_button.get_toplevel());
            dialog.response.connect((response_type) => {
                should_hide();
            });
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