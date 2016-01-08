/* Copyright 2015 Sam Thomas
*
* This file is part of Flower.
*
* Flower is free software: you can redistribute it
* and/or modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation, either version 3 of the
* License, or (at your option) any later version.
*
* Flower is distributed in the hope that it will be
* useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with Flower. If not, see http://www.gnu.org/licenses/.
*/

using Gtk;
using Gdk;
using Cairo;

using Flower.Core;

namespace Flower.Window.View {

    public class PhotoView : Gtk.Box, Flower.Window.View.GenericView {

        private MainWindow window;

        private PhotoDetail? detail;
        private Pixbuf pix; //current picture
        private double zoom = 50.0;
        private bool press = false;
        private bool update_center = true;
        private double start_x = -1;
        private double start_y = -1;
        private int center_x = 0;
        private int center_y = 0;
        private int drag_x = 0;
        private int drag_y = 0;
        private int x_pos = 0;
        private int y_pos = 0;
        private int saved_x = 0;
        private int saved_y = 0;

        //gtk widgets
        private Viewport photo_box;
        private EventBox event_box;
        private DrawingArea canvas;

        private Toolbar toolbar;

        private ToolItem control_revealer_toolitem;
        private Revealer control_revealer;
        private ToolButton slide_show;
        private ToolButton edit_reveal_button;

        private ToolItem edit_revealer_toolitem;
        private Revealer edit_revealer;
        private ToolButton close_edit;
        private ToolButton undo_edit;

        private ToolButton zoom_standard;
        private ToolButton zoom_out;
        private ToolItem zoom_toolitem;
        private Scale zoomer;
        private ToolButton zoom_in;

        private ToolButton go_left;
        private ToolButton go_right;
        private ToolButton info;


        public PhotoView (MainWindow window, PhotoDetail? detail) {
            Object (orientation: Orientation.VERTICAL, spacing: 0);
            this.window = window;

            if (detail != null) {
                this.detail = detail;

                try {
                    pix = new Pixbuf.from_file (this.detail.filepath);
                } catch (GLib.Error e) {
                    critical ("Unable to read %s", this.detail.filepath);
                }

                figure_zoom ();
            }

            setup_layout ();

            connect_signals ();

            show_all ();
        }

        private void figure_zoom () {
            var height = photo_box.get_allocated_height () - 20;
            var width = photo_box.get_allocated_width () - 20;

            if ((double)detail.height / (double)detail.width > (double)height / (double)width) {
                message ("height");
                zoom = ((double) height / (double) detail.height) * 100.0;
            } else {
                message ("width");
                zoom = ((double) width / (double) detail.width) * 100.0;
            }
        }

        private void setup_layout () {
            photo_box = new Viewport (null, null);
            canvas = new DrawingArea ();
            event_box = new EventBox ();
            this.add_events (EventMask.POINTER_MOTION_MASK);
            this.add_events (EventMask.SCROLL_MASK);
            event_box.add (canvas);
            photo_box.add (event_box);
            photo_box.expand = true;

            toolbar = new Toolbar ();
            toolbar.set_show_arrow (true);
            toolbar.expand = false;

            control_revealer_toolitem = new ToolItem ();
            control_revealer = new Revealer ();
            control_revealer.set_transition_type (RevealerTransitionType.SLIDE_LEFT);
            var control_box = new Box (Orientation.HORIZONTAL, 0);
            slide_show = new ToolButton (new Image.from_icon_name ("media-playback-start-symbolic", IconSize.SMALL_TOOLBAR), _("Start Slide show"));
            slide_show.set_tooltip_text (_("Start Slide Show"));
            slide_show.set_sensitive (false);
            control_box.add (slide_show);

            edit_reveal_button = new ToolButton (new Image.from_icon_name ("edit-symbolic", IconSize.SMALL_TOOLBAR), _("Edit"));
            edit_reveal_button.set_tooltip_text (_("Edit Photo"));
            control_box.add (edit_reveal_button);
            control_revealer.add (control_box);
            control_revealer.set_reveal_child (true);
            control_revealer_toolitem.add (control_revealer);
            toolbar.add (control_revealer_toolitem);

            edit_revealer_toolitem = new ToolItem ();
            edit_revealer = new Revealer ();
            edit_revealer.set_transition_type (RevealerTransitionType.SLIDE_LEFT);
            var edit_box = new Box (Orientation.HORIZONTAL, 0);

            close_edit = new ToolButton (new Image.from_icon_name ("document-save-as-symbolic", IconSize.SMALL_TOOLBAR), _("Save"));
            close_edit.set_tooltip_text (_("Save Changes"));
            edit_box.add (close_edit);

            undo_edit = new ToolButton (new Image.from_icon_name ("edit-undo-symbolic", IconSize.SMALL_TOOLBAR), _("Revert"));
            undo_edit.set_tooltip_text (_("Revert to Original Photo"));
            edit_box.add (undo_edit);

            edit_revealer.add (edit_box);
            edit_revealer.set_reveal_child (false);
            edit_revealer_toolitem.add (edit_revealer);
            toolbar.add (edit_revealer_toolitem);

            /* SEPARATOR */
            var sep = new SeparatorToolItem ();
            sep.set_expand (true);
            toolbar.add (sep);
            /* SEPARATOR */

            var img = new Image.from_icon_name ("zoom-original-symbolic", IconSize.SMALL_TOOLBAR);
            img.pixel_size = 16;
            zoom_standard = new ToolButton (img, _("Default Zoom"));
            zoom_standard.set_tooltip_text (_("Default Zoom"));
            toolbar.add (zoom_standard);

            img = new Image.from_icon_name ("zoom-out-symbolic", IconSize.SMALL_TOOLBAR);
            img.pixel_size = 16;
            zoom_out = new ToolButton (img, _("Zoom Out"));
            zoom_out.set_tooltip_text (_("Zoom Out"));
            toolbar.add (zoom_out);

            zoom_toolitem = new ToolItem ();
            zoomer = new Scale.with_range (Orientation.HORIZONTAL, 10.0, 200.0, 1.0);
            zoomer.set_tooltip_text (_("Zoom"));
            zoomer.set_value (zoom);
            zoomer.draw_value = false;
            zoomer.width_request = 200;
            zoom_toolitem.add (zoomer);
            toolbar.add (zoom_toolitem);

            img = new Image.from_icon_name ("zoom-in-symbolic", IconSize.SMALL_TOOLBAR);
            img.pixel_size = 16;
            zoom_in = new ToolButton (img, _("Zoom In"));
            zoom_in.set_tooltip_text (_("Zoom In"));
            toolbar.add (zoom_in);

            go_left = new ToolButton (new Image.from_icon_name ("go-previous-symbolic", IconSize.SMALL_TOOLBAR), _("Previous"));
            go_left.set_tooltip_text (_("Previous Photo"));
            toolbar.add (go_left);

            go_right = new ToolButton (new Image.from_icon_name ("go-next-symbolic", IconSize.SMALL_TOOLBAR), _("Next"));
            go_right.set_tooltip_text (_("Next Photo"));
            toolbar.add (go_right);

            info = new ToolButton (new Image.from_icon_name ("help-info-symbolic", IconSize.SMALL_TOOLBAR), _("Info"));
            info.set_tooltip_text (_("Photo Information"));
            toolbar.add (info);

            this.add (photo_box);
            this.add (toolbar);
        }

        public void set_photo (PhotoDetail detail) {
            this.detail = detail;

            try {
                pix = new Pixbuf.from_file (this.detail.filepath);
            } catch (GLib.Error e) {
                critical ("Unable to read %s", this.detail.filepath);
            }

            figure_zoom ();
            zoomer.set_value (zoom);
        }

        private void toggle_edit (bool editing) {
            if (editing) {
                control_revealer.set_reveal_child (false);
                edit_revealer.set_reveal_child (true);
                toolbar.get_style_context ().add_class ("edit-toolbar");
                go_left.hide ();
                go_right.hide ();
            } else {
                control_revealer.set_reveal_child (true);
                edit_revealer.set_reveal_child (false);
                toolbar.get_style_context ().remove_class ("edit-toolbar");
                go_left.show ();
                go_right.show ();
            }
        }

        private void connect_signals () {
            edit_reveal_button.clicked.connect (() => {
                toggle_edit (true);
            });

            close_edit.clicked.connect (() => {
                toggle_edit (false);
            });

            undo_edit.clicked.connect (() => {
                toggle_edit (false);
            });

            zoomer.value_changed.connect (() => {
                zoom = zoomer.get_value ();
                update_center = true;
                this.queue_draw ();
            });

            zoom_standard.clicked.connect (() => {
                figure_zoom ();
                zoomer.set_value (zoom);
            });

            zoom_out.clicked.connect (() => {
                zoomer.set_value (zoomer.get_value () - preferences.zoom_increment);
            });

            zoom_in.clicked.connect (() => {
                zoomer.set_value (zoomer.get_value () + preferences.zoom_increment);
            });

            go_left.clicked.connect (() => {
                window.show_previous_image ();
            });

            go_right.clicked.connect (() => {
                window.show_next_image ();
            });

            canvas.draw.connect ((cr) => {
                if (this.detail != null) {
                    render (cr);
                }

                return true;
            });

            event_box.event.connect ((e) => {
                if (e.type == EventType.BUTTON_PRESS) {
                    press = true;
                    start_x = e.motion.x;
                    //start_x = x_pos;
                    start_y = e.motion.y;
                    //start_y = y_pos;
                }

                if (e.type == EventType.MOTION_NOTIFY && press) {
                    drag_x = (int)(e.motion.x - start_x);
                    drag_y = (int)(e.motion.y - start_y);
                    //drag_x = (int) e.motion.x;
                    //drag_y = (int) e.motion.y;
                    canvas.queue_draw ();
                }

                if (e.type == EventType.BUTTON_RELEASE) {
                    press = false;
                    drag_x = 0;
                    drag_y = 0;
                    saved_x = x_pos;
                    saved_y = y_pos;
                }

                if (e.type == EventType.SCROLL) {
                    if (e.scroll.direction == ScrollDirection.UP) {
                        zoomer.set_value (zoomer.get_value () + preferences.zoom_increment);
                    } else if (e.scroll.direction == ScrollDirection.DOWN) {
                        zoomer.set_value (zoomer.get_value () - preferences.zoom_increment);
                    }
                }

                return false;
            });

            window.configure_event.connect (() => {
                update_center = true;
                return false;
            });
        }

        private void render (Context cr) {
            var pict = pix.scale_simple ((int) (0.01 * zoom * pix.get_width ()), (int) (0.01 * zoom * pix.get_height ()), InterpType.BILINEAR);
            var width = photo_box.get_allocated_width ();
            var height = photo_box.get_allocated_height ();

            if (update_center) {
                center_x = (width - pict.get_width ()) / 2;
                center_y = (height - pict.get_height ()) / 2;
                x_pos = center_x;
                y_pos = center_y;
                saved_x = x_pos;
                saved_y = y_pos;
                update_center = false;
            } else {
                x_pos = saved_x + drag_x;
                y_pos = saved_y + drag_y;
            }

            cr.translate (x_pos, y_pos);
            Gdk.cairo_set_source_pixbuf (cr, pict, 0, 0);
            cr.paint ();
        }

        public string get_id () {
            return "photo-view";
        }

        public string get_display_name () {
            return "";
        }
    }
}
