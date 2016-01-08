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

using Flower.Core;

namespace Flower.Window.View {

    public class ListView : Gtk.Box, Flower.Window.View.GenericView {

        private MainWindow window;

        private ScrolledWindow scroll;
        private PhotoFlowBox[] content;
        private Box content_box;

        private int flow_id = -1;
        private int index = -1;

        public ListView (MainWindow window) {
            this.window = window;

            scroll = new ScrolledWindow (null, null);
            scroll.expand = true;

            content_box = new Box (Orientation.VERTICAL, 0);

            scroll.add (content_box);

            window.loaded_views.connect (load_photos);

            this.add (scroll);

            connect_signals ();
        }

        private void load_photos () {
            var details = photo_manager.read_data ();
            content = {};
            if (details.length > 0) {
                content += new PhotoFlowBox (this, window, details, "Mo' Photos", 0);
            }

            if (content.length == 0) {
                window.show_welcome ();
            } else {
                window.show_photos ();
                if (content_box.get_children ().length () > 0) {
                    clear_content ();
                }
                foreach (var flow_box in content) {
                    content_box.add (flow_box);
                    flow_box.load ();
                }
            }
        }

        public void update () {
            load_photos ();
        }

        private void clear_content () {
            foreach (var w in content_box.get_children ()) {
                w.destroy ();
            }
        }

        public void show_image (PhotoDetail detail, int flow_id, int index) {
            window.show_image (detail);
            this.flow_id = flow_id;
            this.index = index;
        }

        public bool has_next_image () {
            if (flow_id+1 >= content.length) {
                if (index+1 >= content[flow_id].length) {
                    return false;
                }
            }

            return true;
        }

        public bool has_previous_image () {
            if (flow_id-1 < 0) {
                if (index-1 < 0) {
                    return false;
                }
            }

            return true;
        }

        public void show_next_image () {
            index += 1;
            if (content[flow_id].length < index) {
                index = 0;
                flow_id += 1;
            }

            show_image (content[flow_id].get_detail (index), flow_id, index);
        }

        public void show_previous_image () {
            index -= 1;
            if (index < 0) {
                flow_id -= 1;
                index = content[flow_id].length;
            }

            show_image (content[flow_id].get_detail (index), flow_id, index);
        }

        private void connect_signals () {
        }

        public string get_id () {
            return "list-view";
        }

        public string get_display_name () {
            return _("Photos");
        }
    }

    private class PhotoFlowBox : Gtk.Box {

        private ListView list_view;
        private MainWindow window;

        private PhotoDetail[] details;

        private string title;
        private int id;

        private Box title_box;
        private FlowBox flow_box;

        public int length;

        public PhotoFlowBox (ListView list_view, MainWindow window, PhotoDetail[] details, string title, int id) {
            Object (orientation: Orientation.VERTICAL, spacing: 5);

            this.list_view = list_view;
            this.window = window;
            this.details = details;
            this.id = id;

            //initalize variables
            this.title = title;
            title_box = new Box (Orientation.HORIZONTAL, 0);
            flow_box = new FlowBox ();

            //flowbox settings
            flow_box.column_spacing = preferences.spacing;
            flow_box.row_spacing = preferences.spacing;
            flow_box.border_width = preferences.spacing;
            flow_box.min_children_per_line = preferences.photos_per_row;
            flow_box.halign = Align.CENTER;
            flow_box.selection_mode = SelectionMode.NONE;

            setup_label ();

            //add things to this
            this.add (title_box);
            this.add (flow_box);

            this.show_all ();
        }

        public void append (Widget w) {
            flow_box.add (w);
            length += 1;
        }

        public PhotoDetail get_detail (int index) {
            return details[index];
        }

        public void load () {
            var n = preferences.photos_per_row;
            var space = preferences.spacing;
            var width = window.get_width () - 110;
            //var width = 1197 - 110;
            var factor = ((width-(2.0*space*n)-5)/n);

            //message (width.to_string ());
            //message (factor.to_string ());

            foreach (var det in details) {
                var photo = new PhotoImage (list_view, id, det, (int) factor);
                this.append (photo);
                photo.show_all ();

                while (Gtk.events_pending ()) {
                    Gtk.main_iteration ();
                }
            }
        }

        private void setup_label () {
            var label = new Label (this.title);
            label.halign = Align.CENTER;
            label.valign = Align.CENTER;
            label.hexpand = true;
            label.vexpand = false;
            label.get_style_context ().add_class ("photo-flow-box-label");
            title_box.add (label);
        }
    }

    private class PhotoImage : Gtk.FlowBoxChild {

        private ListView list_view;
        private int id;
        private PhotoDetail detail;

        private EventBox event_box;

        private Pixbuf raw;
        private Pixbuf thumb;
        private static Pixbuf checked = null;
        private static Pixbuf hover_check = null;
        private static Pixbuf hover_uncheck = null;

        private RGBA selected_color;
        private RGBA hover_color;

        private bool selection_mode;

        private int thumb_margin = 3;

        public PhotoImage (ListView list_view, int id, PhotoDetail pdetail, int size) {
            this.list_view = list_view;
            this.id = id;
            this.detail = pdetail;

            event_box = new EventBox ();
            this.add (event_box);

            try {
                raw = new Pixbuf.from_file (detail.filepath);
            } catch (GLib.Error e) {
                critical ("Unable to read %s", detail.filepath);
            }

            thumb = scale (raw, size);

            //load selected color
            selected_color = this.get_style_context ().get_background_color (Gtk.StateFlags.SELECTED);
            hover_color = this.get_style_context ().get_color (Gtk.StateFlags.SELECTED);

            this.height_request = thumb.get_height () + 2*thumb_margin;
            this.width_request = thumb.get_width () + 2*thumb_margin;
            //scaled = raw

            if (checked == null) {
                try {
                    var icon_theme = Gtk.IconTheme.get_default ();
                    checked = icon_theme.load_icon ("selection-checked", 16, IconLookupFlags.FORCE_SIZE);
                } catch (GLib.Error e) {
                    warning ("Getting selection-checked from icon-theme failed!");
                }
            }

            if (hover_check == null) {
                try {
                    var icon_theme = Gtk.IconTheme.get_default ();
                    hover_check = icon_theme.load_icon ("selection-add", 16, IconLookupFlags.FORCE_SIZE);
                } catch (GLib.Error e) {
                    warning ("Getting selection-add from icon-theme failed!");
                }
            }

            if (hover_uncheck == null) {
                try {
                    var icon_theme = Gtk.IconTheme.get_default ();
                    hover_uncheck = icon_theme.load_icon ("selection-remove", 16, IconLookupFlags.FORCE_SIZE);
                } catch (GLib.Error e) {
                    warning ("Getting selection-remove from icon-theme failed!");
                }
            }

            this.add_events (EventMask.POINTER_MOTION_MASK);
            this.add_events (EventMask.KEY_PRESS_MASK);

            event_box.event.connect ((e) => {
                if (e.type == EventType.ENTER_NOTIFY) {
                    set_hover (true);
                } else if (e.type == EventType.LEAVE_NOTIFY) {
                    set_hover (false);
                }

                if (e.type == EventType.BUTTON_PRESS) {
                    if (selection_mode) {
                        set_selected (!get_selected ());
                    } else {
                        list_view.show_image (detail, id, this.get_index ());
                    }
                }

                if (e.type == EventType.KEY_PRESS) {
                    message ("yu");
                    message (e.key.str + " " + e.key.hardware_keycode.to_string () + " " + e.key.group.to_string ());
                }

                return false;
            });
        }

        public Pixbuf scale (Pixbuf pix, int size) {
            //message ("scaling");
            int big;
            if (detail.height > detail.width) {
                big = detail.height;
            } else {
                big = detail.width;
            }

            var factor = (double) big / (double) size;

            return pix.scale_simple ((int) (detail.width/factor), (int) (detail.height/factor), InterpType.NEAREST);
        }

        public void set_hover (bool is_hover) {
            if (is_hover) {
                set_state_flags (get_state_flags () | Gtk.StateFlags.PRELIGHT, false);
            } else {
                unset_state_flags (Gtk.StateFlags.PRELIGHT);
            }
            queue_draw ();
        }

        public void set_selected (bool is_selected) {
            if (is_selected) {
                set_state_flags (get_state_flags () | Gtk.StateFlags.SELECTED, false);
            } else {
                unset_state_flags (Gtk.StateFlags.SELECTED);
            }
            queue_draw ();
        }

        public bool get_selected () {
            return ((get_state_flags () & Gtk.StateFlags.SELECTED) == Gtk.StateFlags.SELECTED);
        }

        public override bool draw (Cairo.Context cr) {
            int width = thumb.get_width () + 2*thumb_margin;
            int height = thumb.get_height () + 2*thumb_margin;

            var center_x = (event_box.get_allocated_width () - width) / 2;
            var center_y = (event_box.get_allocated_height () - height) / 2;

            if ((get_state_flags () & StateFlags.SELECTED) == StateFlags.SELECTED) {
                cr.save ();
                cr.set_source_rgba (selected_color.red, selected_color.green, selected_color.blue, selected_color.alpha);
                cr.translate (center_x, center_y);
                Granite.Drawing.Utilities.cairo_rounded_rectangle (cr, 0, 0, width, height, 3);
                //Granite.Drawing.Utilities.cairo_rounded_rectangle (cr, 0, 0, event_box.get_allocated_width (), event_box.get_allocated_height (), 3);
                cr.fill ();
                cr.restore ();
            }

            if ((get_state_flags () & Gtk.StateFlags.PRELIGHT) == Gtk.StateFlags.PRELIGHT) {
                cr.save ();
                cr.set_source_rgba (hover_color.red, hover_color.green, hover_color.blue, hover_color.alpha);
                cr.translate (center_x, center_y);
                Granite.Drawing.Utilities.cairo_rounded_rectangle (cr, 0, 0, width, height, 3);
                cr.fill ();
                cr.restore ();
            }

            cr.save ();
            //message ("%i %i", center_x, center_y);
            cr.translate (center_x, center_y);
            Gdk.cairo_set_source_pixbuf (cr, thumb, 3, 3);
            cr.paint ();

            //checked stuff
            if ((get_state_flags () & StateFlags.PRELIGHT) == StateFlags.PRELIGHT) {
                if ((get_state_flags () & Gtk.StateFlags.SELECTED) == Gtk.StateFlags.SELECTED) {
                    int x = hover_uncheck.get_width ()/2;
                    int y = hover_uncheck.get_height ()/2;

                    Gdk.cairo_set_source_pixbuf (cr, hover_uncheck, x, y);
                    cr.paint ();
                } else {
                    int x = hover_check.get_width ()/2;
                    int y = hover_check.get_height ()/2;

                    Gdk.cairo_set_source_pixbuf (cr, hover_check, x, y);
                    cr.paint ();
                }
            } else if ((get_state_flags () & Gtk.StateFlags.SELECTED) == Gtk.StateFlags.SELECTED) {
                int x = checked.get_width ()/2;
                int y = checked.get_height ()/2;

                Gdk.cairo_set_source_pixbuf (cr, checked, x, y);
                cr.paint ();
            }

            cr.restore ();
            return true;
        }
    }

}
