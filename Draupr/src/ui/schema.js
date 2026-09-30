window.DRAUPR_SCHEMA = {
  "version": "4.1.26",
  "schemaVersion": 1,
  "tools": [
    {
      "id": "wall",
      "label": "Wall",
      "fa": "دیوار",
      "category": "envelope",
      "mode": "path",
      "fields": [
        {
          "key": "length",
          "label": "Length (origin creation)",
          "fa": "طول (ساخت در مبدا)",
          "type": "length",
          "default": "4000 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "height",
          "label": "Height",
          "fa": "ارتفاع",
          "type": "length",
          "default": "3000 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "thickness",
          "label": "Overall thickness",
          "fa": "ضخامت کل",
          "type": "length",
          "default": "200 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "alignment",
          "label": "Reference-line alignment",
          "fa": "تراز نسبت به خط",
          "type": "select",
          "default": "center",
          "section": "geometry",
          "options": [
            {
              "value": "center",
              "label": "Center",
              "fa": "مرکز"
            },
            {
              "value": "inside",
              "label": "Left / inside",
              "fa": "چپ / داخل"
            },
            {
              "value": "outside",
              "label": "Right / outside",
              "fa": "راست / بیرون"
            }
          ]
        },
        {
          "key": "wall_type",
          "label": "Construction",
          "fa": "ساختار",
          "type": "select",
          "default": "single",
          "section": "geometry",
          "options": [
            {
              "value": "single",
              "label": "Solid / layered",
              "fa": "توپر / لایه‌ای"
            },
            {
              "value": "cavity",
              "label": "Cavity wall",
              "fa": "دیوار حفره‌دار"
            }
          ]
        },
        {
          "key": "assembly",
          "label": "Assembly",
          "fa": "ترکیب لایه‌ها",
          "type": "select",
          "default": "custom",
          "section": "geometry",
          "options": [
            {
              "value": "custom",
              "label": "Single material",
              "fa": "تک‌متریال"
            },
            {
              "value": "concrete",
              "label": "Concrete + finishes",
              "fa": "بتن + نازک‌کاری"
            },
            {
              "value": "brick",
              "label": "Brick + finishes",
              "fa": "آجر + نازک‌کاری"
            },
            {
              "value": "stud",
              "label": "Stud + finishes",
              "fa": "استاد + نازک‌کاری"
            },
            {
              "value": "layered",
              "label": "Custom three-layer",
              "fa": "سه‌لایه سفارشی"
            }
          ]
        },
        {
          "key": "cavity_width",
          "label": "Cavity width",
          "fa": "عرض حفره",
          "type": "length",
          "default": "60 mm",
          "section": "geometry",
          "min": 0.5,
          "show": {
            "wall_type": "cavity"
          }
        },
        {
          "key": "inner_thickness",
          "label": "Interior finish thickness",
          "fa": "ضخامت نازک‌کاری داخلی",
          "type": "length",
          "default": "15 mm",
          "section": "geometry",
          "min": 0.5,
          "showNot": {
            "assembly": "custom"
          }
        },
        {
          "key": "outer_thickness",
          "label": "Exterior finish thickness",
          "fa": "ضخامت نازک‌کاری خارجی",
          "type": "length",
          "default": "15 mm",
          "section": "geometry",
          "min": 0.5,
          "showNot": {
            "assembly": "custom"
          }
        },
        {
          "key": "core_material",
          "label": "Core",
          "fa": "هسته",
          "type": "material",
          "default": "Draupr Wall - Warm Concrete",
          "section": "materials"
        },
        {
          "key": "inner_material",
          "label": "Interior finish",
          "fa": "نازک‌کاری داخل",
          "type": "material",
          "default": "Draupr Finish - Soft Plaster",
          "section": "materials"
        },
        {
          "key": "outer_material",
          "label": "Exterior finish",
          "fa": "نازک‌کاری بیرون",
          "type": "material",
          "default": "Draupr Finish - Soft Plaster",
          "section": "materials"
        },
        {
          "key": "placement_mode",
          "label": "Elevation source",
          "fa": "مبنای ارتفاع",
          "type": "select",
          "default": "level",
          "section": "placement",
          "options": [
            {
              "value": "level",
              "label": "Project level",
              "fa": "تراز پروژه"
            },
            {
              "value": "surface",
              "label": "Picked surface",
              "fa": "سطح انتخابی"
            }
          ]
        },
        {
          "key": "level_id",
          "label": "Level",
          "fa": "تراز",
          "type": "level",
          "default": "ground",
          "section": "placement"
        },
        {
          "key": "z_offset",
          "label": "Level / surface offset",
          "fa": "آفست ارتفاع",
          "type": "length",
          "default": "0 mm",
          "section": "placement",
          "min": -100000
        },
        {
          "key": "rotation",
          "label": "Additional rotation (°)",
          "fa": "چرخش افزوده (درجه)",
          "type": "number",
          "default": 0,
          "section": "placement",
          "min": -360,
          "max": 360
        },
        {
          "key": "name",
          "label": "Object name",
          "fa": "نام آبجکت",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "mark",
          "label": "Mark / type code",
          "fa": "کد / مارک",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "tag",
          "label": "Tag (blank = automatic)",
          "fa": "تگ (خالی = خودکار)",
          "type": "text",
          "default": "",
          "section": "advanced"
        }
      ],
      "roles": [
        {
          "id": "core",
          "label": "Core",
          "fa": "هسته",
          "key": "core_material"
        },
        {
          "id": "inner",
          "label": "Interior",
          "fa": "داخل",
          "key": "inner_material"
        },
        {
          "id": "outer",
          "label": "Exterior",
          "fa": "بیرون",
          "key": "outer_material"
        }
      ],
      "hint": "Click a chain of points. Up arrow or right-click toggles arc segments. Space, Enter or double-click finishes. Esc steps back. One completed chain = one Undo.",
      "faHint": "نقاط مسیر را کلیک کنید؛ برای قوس کلید Up یا راست‌کلیک؛ پایان با Space یا Enter یا دوبارکلیک؛ Esc یک مرحله عقب. هر مسیر یک واگرد دارد."
    },
    {
      "id": "curtain_wall",
      "label": "Curtain wall",
      "fa": "کرتین‌وال",
      "category": "envelope",
      "mode": "line",
      "fields": [
        {
          "key": "width",
          "label": "Width",
          "fa": "عرض",
          "type": "length",
          "default": "5000 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "height",
          "label": "Height",
          "fa": "ارتفاع",
          "type": "length",
          "default": "3200 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "grid_mode",
          "label": "Grid controlled by",
          "fa": "کنترل شبکه",
          "type": "select",
          "default": "spacing",
          "section": "geometry",
          "options": [
            {
              "value": "spacing",
              "label": "Target spacing",
              "fa": "فاصله هدف"
            },
            {
              "value": "count",
              "label": "Panel count",
              "fa": "تعداد پنل"
            }
          ]
        },
        {
          "key": "grid_x",
          "label": "Target bay width",
          "fa": "عرض هدف دهانه",
          "type": "length",
          "default": "1200 mm",
          "section": "geometry",
          "min": 0.5,
          "show": {
            "grid_mode": "spacing"
          }
        },
        {
          "key": "grid_y",
          "label": "Target bay height",
          "fa": "ارتفاع هدف دهانه",
          "type": "length",
          "default": "1000 mm",
          "section": "geometry",
          "min": 0.5,
          "show": {
            "grid_mode": "spacing"
          }
        },
        {
          "key": "count_x",
          "label": "Columns",
          "fa": "ستون‌های پنل",
          "type": "integer",
          "default": 4,
          "section": "geometry",
          "min": 1,
          "max": 80,
          "show": {
            "grid_mode": "count"
          }
        },
        {
          "key": "count_y",
          "label": "Rows",
          "fa": "ردیف‌های پنل",
          "type": "integer",
          "default": 3,
          "section": "geometry",
          "min": 1,
          "max": 80,
          "show": {
            "grid_mode": "count"
          }
        },
        {
          "key": "distribution",
          "label": "Remainder distribution",
          "fa": "تقسیم باقیمانده",
          "type": "select",
          "default": "equal",
          "section": "geometry",
          "options": [
            {
              "value": "equal",
              "label": "Equal bays",
              "fa": "دهانه‌های مساوی"
            },
            {
              "value": "last",
              "label": "Last bay",
              "fa": "دهانه آخر"
            }
          ],
          "show": {
            "grid_mode": "spacing"
          }
        },
        {
          "key": "mullion_width",
          "label": "Mullion width",
          "fa": "عرض مولیون",
          "type": "length",
          "default": "80 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "mullion_depth",
          "label": "Frame depth",
          "fa": "عمق قاب",
          "type": "length",
          "default": "120 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "transom_width",
          "label": "Transom height",
          "fa": "ارتفاع ترنسوم",
          "type": "length",
          "default": "80 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "glass_thickness",
          "label": "Glass thickness",
          "fa": "ضخامت شیشه",
          "type": "length",
          "default": "12 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "glass_material",
          "label": "Vision glass",
          "fa": "شیشه دید",
          "type": "material",
          "default": "Draupr Glass - Clear Blue",
          "section": "materials"
        },
        {
          "key": "mullion_material",
          "label": "Mullions",
          "fa": "مولیون‌ها",
          "type": "material",
          "default": "Draupr Mullion - Graphite",
          "section": "materials"
        },
        {
          "key": "transom_material",
          "label": "Transoms",
          "fa": "ترنسوم‌ها",
          "type": "material",
          "default": "Draupr Mullion - Graphite",
          "section": "materials"
        },
        {
          "key": "panel_material",
          "label": "Spandrel / infill",
          "fa": "اسپندرل / پنل توپر",
          "type": "material",
          "default": "Draupr Steel - Satin",
          "section": "materials"
        },
        {
          "key": "placement_mode",
          "label": "Elevation source",
          "fa": "مبنای ارتفاع",
          "type": "select",
          "default": "level",
          "section": "placement",
          "options": [
            {
              "value": "level",
              "label": "Project level",
              "fa": "تراز پروژه"
            },
            {
              "value": "surface",
              "label": "Picked surface",
              "fa": "سطح انتخابی"
            }
          ]
        },
        {
          "key": "level_id",
          "label": "Level",
          "fa": "تراز",
          "type": "level",
          "default": "ground",
          "section": "placement"
        },
        {
          "key": "z_offset",
          "label": "Level / surface offset",
          "fa": "آفست ارتفاع",
          "type": "length",
          "default": "0 mm",
          "section": "placement",
          "min": -100000
        },
        {
          "key": "rotation",
          "label": "Additional rotation (°)",
          "fa": "چرخش افزوده (درجه)",
          "type": "number",
          "default": 0,
          "section": "placement",
          "min": -360,
          "max": 360
        },
        {
          "key": "name",
          "label": "Object name",
          "fa": "نام آبجکت",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "mark",
          "label": "Mark / type code",
          "fa": "کد / مارک",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "tag",
          "label": "Tag (blank = automatic)",
          "fa": "تگ (خالی = خودکار)",
          "type": "text",
          "default": "",
          "section": "advanced"
        }
      ],
      "roles": [
        {
          "id": "glass",
          "label": "Glass",
          "fa": "شیشه",
          "key": "glass_material"
        },
        {
          "id": "mullion",
          "label": "Mullions",
          "fa": "مولیون",
          "key": "mullion_material"
        },
        {
          "id": "transom",
          "label": "Transoms",
          "fa": "ترنسوم",
          "key": "transom_material"
        },
        {
          "id": "infill",
          "label": "Opaque infill",
          "fa": "پنل توپر",
          "key": "panel_material"
        }
      ],
      "hint": "Draw a baseline. Height and panel grid are previewed. Select a panel in Materials to override it.",
      "faHint": "خط مبنا را رسم کنید. ارتفاع و شبکه پیش‌نمایش می‌شوند؛ برای تغییر هر پنل به متریال‌ها بروید."
    },
    {
      "id": "door",
      "label": "Door",
      "fa": "درب",
      "category": "envelope",
      "mode": "host",
      "fields": [
        {
          "key": "door_type",
          "label": "Door Type",
          "fa": "نوع در",
          "type": "select",
          "default": "single",
          "section": "geometry",
          "options": [
            {
              "value": "single",
              "label": "Single Swing",
              "fa": "تک‌لنگه"
            },
            {
              "value": "double",
              "label": "Double",
              "fa": "دولنگه"
            },
            {
              "value": "sliding",
              "label": "Sliding",
              "fa": "کشویی"
            },
            {
              "value": "glazed",
              "label": "Glazed",
              "fa": "شیشه‌دار"
            }
          ]
        },
        {
          "key": "width",
          "label": "Width",
          "fa": "عرض",
          "type": "length",
          "default": "900 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "height",
          "label": "Height",
          "fa": "ارتفاع",
          "type": "length",
          "default": "2100 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "depth",
          "label": "Frame depth (host sets on placement)",
          "fa": "عمق قاب (از دیوار میزبان)",
          "type": "length",
          "default": "200 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "frame",
          "label": "Frame size",
          "fa": "اندازه قاب",
          "type": "length",
          "default": "70 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "host_offset",
          "label": "Left-edge offset along host wall",
          "fa": "فاصله لبه چپ از ابتدای دیوار",
          "type": "length",
          "default": "0 mm",
          "section": "placement",
          "min": 0
        },
        {
          "key": "flip",
          "label": "Reverse facing",
          "fa": "معکوس کردن رو",
          "type": "boolean",
          "default": false,
          "section": "placement"
        },
        {
          "key": "leaf_thickness",
          "label": "Leaf thickness",
          "fa": "ضخامت لنگه",
          "type": "length",
          "default": "40 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "swing_angle",
          "label": "Leaf opening angle (°)",
          "fa": "زاویه بازشدن لنگه",
          "type": "number",
          "default": 0,
          "section": "geometry",
          "min": 0,
          "max": 170
        },
        {
          "key": "handing",
          "label": "Hinge side",
          "fa": "سمت لولا",
          "type": "select",
          "default": "left",
          "section": "geometry",
          "options": [
            {
              "value": "left",
              "label": "Left",
              "fa": "چپ"
            },
            {
              "value": "right",
              "label": "Right",
              "fa": "راست"
            }
          ]
        },
        {
          "key": "frame_material",
          "label": "Frame",
          "fa": "قاب",
          "type": "material",
          "default": "Draupr Timber - Oak",
          "section": "materials"
        },
        {
          "key": "leaf_material",
          "label": "Leaf",
          "fa": "لنگه",
          "type": "material",
          "default": "Draupr Door - Walnut",
          "section": "materials"
        },
        {
          "key": "glass_material",
          "label": "Glass Material",
          "fa": "متریال شیشه",
          "type": "material",
          "default": "Draupr Glass - Clear Blue",
          "section": "materials",
          "show": {
            "door_type": "glazed"
          }
        },
        {
          "key": "placement_mode",
          "label": "Elevation source",
          "fa": "مبنای ارتفاع",
          "type": "select",
          "default": "level",
          "section": "placement",
          "options": [
            {
              "value": "level",
              "label": "Project level",
              "fa": "تراز پروژه"
            },
            {
              "value": "surface",
              "label": "Picked surface",
              "fa": "سطح انتخابی"
            }
          ]
        },
        {
          "key": "level_id",
          "label": "Level",
          "fa": "تراز",
          "type": "level",
          "default": "ground",
          "section": "placement"
        },
        {
          "key": "z_offset",
          "label": "Level / surface offset",
          "fa": "آفست ارتفاع",
          "type": "length",
          "default": "0 mm",
          "section": "placement",
          "min": -100000
        },
        {
          "key": "rotation",
          "label": "Additional rotation (°)",
          "fa": "چرخش افزوده (درجه)",
          "type": "number",
          "default": 0,
          "section": "placement",
          "min": -360,
          "max": 360
        },
        {
          "key": "name",
          "label": "Object name",
          "fa": "نام آبجکت",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "mark",
          "label": "Mark / type code",
          "fa": "کد / مارک",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "tag",
          "label": "Tag (blank = automatic)",
          "fa": "تگ (خالی = خودکار)",
          "type": "text",
          "default": "",
          "section": "advanced"
        }
      ],
      "roles": [
        {
          "id": "frame",
          "label": "Frame",
          "fa": "قاب",
          "key": "frame_material"
        },
        {
          "id": "leaf",
          "label": "Leaf",
          "fa": "لنگه",
          "key": "leaf_material"
        }
      ],
      "hint": "Hover a Draupr wall, then click. Editing size or offset also updates the linked wall opening.",
      "faHint": "روی دیوار Draupr مکث و کلیک کنید. ویرایش ابعاد یا فاصله، بازشوی دیوار را هم به‌روز می‌کند."
    },
    {
      "id": "window",
      "label": "Window",
      "fa": "پنجره",
      "category": "envelope",
      "mode": "host",
      "fields": [
        {
          "key": "window_type",
          "label": "Window Type",
          "fa": "نوع پنجره",
          "type": "select",
          "default": "fixed",
          "section": "geometry",
          "options": [
            {
              "value": "fixed",
              "label": "Fixed / Picture",
              "fa": "ثابت"
            },
            {
              "value": "double_hung",
              "label": "Double-Hung",
              "fa": "ساش دوتایی"
            },
            {
              "value": "casement",
              "label": "Casement",
              "fa": "لولایی"
            },
            {
              "value": "sliding",
              "label": "Sliding",
              "fa": "کشویی"
            },
            {
              "value": "arched",
              "label": "Arched Top",
              "fa": "طاقی"
            }
          ]
        },
        {
          "key": "width",
          "label": "Width",
          "fa": "عرض",
          "type": "length",
          "default": "1200 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "height",
          "label": "Height",
          "fa": "ارتفاع",
          "type": "length",
          "default": "1200 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "sill",
          "label": "Sill height",
          "fa": "ارتفاع کف پنجره",
          "type": "length",
          "default": "900 mm",
          "section": "geometry",
          "min": 0
        },
        {
          "key": "depth",
          "label": "Frame depth (host sets on placement)",
          "fa": "عمق قاب (از دیوار میزبان)",
          "type": "length",
          "default": "200 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "frame",
          "label": "Frame size",
          "fa": "اندازه قاب",
          "type": "length",
          "default": "60 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "host_offset",
          "label": "Left-edge offset along host wall",
          "fa": "فاصله لبه چپ از ابتدای دیوار",
          "type": "length",
          "default": "0 mm",
          "section": "placement",
          "min": 0
        },
        {
          "key": "flip",
          "label": "Reverse facing",
          "fa": "معکوس کردن رو",
          "type": "boolean",
          "default": false,
          "section": "placement"
        },
        {
          "key": "mullions",
          "label": "Vertical mullions",
          "fa": "مولیون عمودی",
          "type": "integer",
          "default": 0,
          "section": "geometry",
          "min": 0,
          "max": 20
        },
        {
          "key": "glass_thickness",
          "label": "Glass thickness",
          "fa": "ضخامت شیشه",
          "type": "length",
          "default": "12 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "frame_material",
          "label": "Frame",
          "fa": "قاب",
          "type": "material",
          "default": "Draupr Mullion - Graphite",
          "section": "materials"
        },
        {
          "key": "glass_material",
          "label": "Glass",
          "fa": "شیشه",
          "type": "material",
          "default": "Draupr Glass - Clear Blue",
          "section": "materials"
        },
        {
          "key": "placement_mode",
          "label": "Elevation source",
          "fa": "مبنای ارتفاع",
          "type": "select",
          "default": "level",
          "section": "placement",
          "options": [
            {
              "value": "level",
              "label": "Project level",
              "fa": "تراز پروژه"
            },
            {
              "value": "surface",
              "label": "Picked surface",
              "fa": "سطح انتخابی"
            }
          ]
        },
        {
          "key": "level_id",
          "label": "Level",
          "fa": "تراز",
          "type": "level",
          "default": "ground",
          "section": "placement"
        },
        {
          "key": "z_offset",
          "label": "Level / surface offset",
          "fa": "آفست ارتفاع",
          "type": "length",
          "default": "0 mm",
          "section": "placement",
          "min": -100000
        },
        {
          "key": "rotation",
          "label": "Additional rotation (°)",
          "fa": "چرخش افزوده (درجه)",
          "type": "number",
          "default": 0,
          "section": "placement",
          "min": -360,
          "max": 360
        },
        {
          "key": "name",
          "label": "Object name",
          "fa": "نام آبجکت",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "mark",
          "label": "Mark / type code",
          "fa": "کد / مارک",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "tag",
          "label": "Tag (blank = automatic)",
          "fa": "تگ (خالی = خودکار)",
          "type": "text",
          "default": "",
          "section": "advanced"
        }
      ],
      "roles": [
        {
          "id": "frame",
          "label": "Frame",
          "fa": "قاب",
          "key": "frame_material"
        },
        {
          "id": "glass",
          "label": "Glass",
          "fa": "شیشه",
          "key": "glass_material"
        }
      ],
      "hint": "Hover a Draupr wall, then click. Editing size or offset also updates the linked wall opening.",
      "faHint": "روی دیوار Draupr مکث و کلیک کنید. ویرایش ابعاد یا فاصله، بازشوی دیوار را هم به‌روز می‌کند."
    },
    {
      "id": "column",
      "label": "Column",
      "fa": "ستون",
      "category": "structure",
      "mode": "point",
      "fields": [
        {
          "key": "shape",
          "label": "Section shape",
          "fa": "شکل مقطع",
          "type": "select",
          "default": "rectangular",
          "section": "geometry",
          "options": [
            {
              "value": "rectangular",
              "label": "Rectangular",
              "fa": "مستطیل"
            },
            {
              "value": "round",
              "label": "Round",
              "fa": "دایره"
            }
          ]
        },
        {
          "key": "width",
          "label": "Width",
          "fa": "عرض",
          "type": "length",
          "default": "400 mm",
          "section": "geometry",
          "min": 0.5,
          "show": {
            "shape": "rectangular"
          }
        },
        {
          "key": "depth",
          "label": "Depth",
          "fa": "عمق",
          "type": "length",
          "default": "400 mm",
          "section": "geometry",
          "min": 0.5,
          "show": {
            "shape": "rectangular"
          }
        },
        {
          "key": "radius",
          "label": "Radius",
          "fa": "شعاع",
          "type": "length",
          "default": "200 mm",
          "section": "geometry",
          "min": 0.5,
          "show": {
            "shape": "round"
          }
        },
        {
          "key": "height",
          "label": "Height",
          "fa": "ارتفاع",
          "type": "length",
          "default": "3000 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "material",
          "label": "Structure",
          "fa": "سازه",
          "type": "material",
          "default": "Draupr Concrete - Structural",
          "section": "materials"
        },
        {
          "key": "placement_mode",
          "label": "Elevation source",
          "fa": "مبنای ارتفاع",
          "type": "select",
          "default": "level",
          "section": "placement",
          "options": [
            {
              "value": "level",
              "label": "Project level",
              "fa": "تراز پروژه"
            },
            {
              "value": "surface",
              "label": "Picked surface",
              "fa": "سطح انتخابی"
            }
          ]
        },
        {
          "key": "level_id",
          "label": "Level",
          "fa": "تراز",
          "type": "level",
          "default": "ground",
          "section": "placement"
        },
        {
          "key": "z_offset",
          "label": "Level / surface offset",
          "fa": "آفست ارتفاع",
          "type": "length",
          "default": "0 mm",
          "section": "placement",
          "min": -100000
        },
        {
          "key": "rotation",
          "label": "Additional rotation (°)",
          "fa": "چرخش افزوده (درجه)",
          "type": "number",
          "default": 0,
          "section": "placement",
          "min": -360,
          "max": 360
        },
        {
          "key": "name",
          "label": "Object name",
          "fa": "نام آبجکت",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "mark",
          "label": "Mark / type code",
          "fa": "کد / مارک",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "tag",
          "label": "Tag (blank = automatic)",
          "fa": "تگ (خالی = خودکار)",
          "type": "text",
          "default": "",
          "section": "advanced"
        }
      ],
      "roles": [
        {
          "id": "structure",
          "label": "Structure",
          "fa": "سازه",
          "key": "material"
        }
      ],
      "hint": "Click the column center. Repeat placement can remain active.",
      "faHint": "مرکز ستون را کلیک کنید. جای‌گذاری تکراری می‌تواند فعال بماند."
    },
    {
      "id": "foundation",
      "label": "Foundation",
      "fa": "فونداسیون",
      "category": "structure",
      "mode": "point",
      "fields": [
        {
          "key": "foundation_type",
          "label": "Foundation Type",
          "fa": "نوع شالوده",
          "type": "select",
          "default": "pad",
          "section": "geometry",
          "options": [
            {
              "value": "pad",
              "label": "Pad Footing",
              "fa": "پایه منفرد"
            },
            {
              "value": "raft",
              "label": "Raft / Mat Slab",
              "fa": "صفحی (لچکی)"
            },
            {
              "value": "strip",
              "label": "Strip / Linear",
              "fa": "نواری"
            }
          ]
        },
        {
          "key": "width",
          "label": "Width",
          "fa": "عرض",
          "type": "length",
          "default": "1600 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "depth",
          "label": "Depth",
          "fa": "عمق",
          "type": "length",
          "default": "1600 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "height",
          "label": "Height",
          "fa": "ارتفاع",
          "type": "length",
          "default": "400 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "edge_beam",
          "label": "Thickened Edge Beam",
          "fa": "تیر لبه‌ای",
          "type": "boolean",
          "default": false,
          "section": "geometry",
          "show": {
            "foundation_type": "raft"
          }
        },
        {
          "key": "material",
          "label": "Concrete",
          "fa": "بتن",
          "type": "material",
          "default": "Draupr Foundation - Concrete",
          "section": "materials"
        },
        {
          "key": "placement_mode",
          "label": "Elevation source",
          "fa": "مبنای ارتفاع",
          "type": "select",
          "default": "level",
          "section": "placement",
          "options": [
            {
              "value": "level",
              "label": "Project level",
              "fa": "تراز پروژه"
            },
            {
              "value": "surface",
              "label": "Picked surface",
              "fa": "سطح انتخابی"
            }
          ]
        },
        {
          "key": "level_id",
          "label": "Level",
          "fa": "تراز",
          "type": "level",
          "default": "ground",
          "section": "placement"
        },
        {
          "key": "z_offset",
          "label": "Level / surface offset",
          "fa": "آفست ارتفاع",
          "type": "length",
          "default": "0 mm",
          "section": "placement",
          "min": -100000
        },
        {
          "key": "rotation",
          "label": "Additional rotation (°)",
          "fa": "چرخش افزوده (درجه)",
          "type": "number",
          "default": 0,
          "section": "placement",
          "min": -360,
          "max": 360
        },
        {
          "key": "name",
          "label": "Object name",
          "fa": "نام آبجکت",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "mark",
          "label": "Mark / type code",
          "fa": "کد / مارک",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "tag",
          "label": "Tag (blank = automatic)",
          "fa": "تگ (خالی = خودکار)",
          "type": "text",
          "default": "",
          "section": "advanced"
        }
      ],
      "roles": [
        {
          "id": "structure",
          "label": "Structure",
          "fa": "سازه",
          "key": "material"
        }
      ],
      "hint": "Pad: click to place. Raft: drag the slab footprint. Strip: click a path along wall lines; Space, Enter or double-click finishes.",
      "faHint": "پایه منفرد: کلیک برای قرارگیری. صفحی: ردپای داله را بکشید. نواری: مسیری در امتداد دیوارها کلیک کنید؛ پایان با Space یا Enter یا دوبارکلیک."
    },
    {
      "id": "beam",
      "label": "Beam",
      "fa": "تیر",
      "category": "structure",
      "mode": "line",
      "fields": [
        {
          "key": "length",
          "label": "Length",
          "fa": "طول",
          "type": "length",
          "default": "4000 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "width",
          "label": "Section width",
          "fa": "عرض مقطع",
          "type": "length",
          "default": "250 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "height",
          "label": "Section height",
          "fa": "ارتفاع مقطع",
          "type": "length",
          "default": "450 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "alignment",
          "label": "Baseline alignment",
          "fa": "تراز خط مبنا",
          "type": "select",
          "default": "center",
          "section": "geometry",
          "options": [
            {
              "value": "center",
              "label": "Center",
              "fa": "مرکز"
            },
            {
              "value": "inside",
              "label": "Left / inside",
              "fa": "چپ / داخل"
            },
            {
              "value": "outside",
              "label": "Right / outside",
              "fa": "راست / بیرون"
            }
          ]
        },
        {
          "key": "material",
          "label": "Structure",
          "fa": "سازه",
          "type": "material",
          "default": "Draupr Concrete - Structural",
          "section": "materials"
        },
        {
          "key": "placement_mode",
          "label": "Elevation source",
          "fa": "مبنای ارتفاع",
          "type": "select",
          "default": "level",
          "section": "placement",
          "options": [
            {
              "value": "level",
              "label": "Project level",
              "fa": "تراز پروژه"
            },
            {
              "value": "surface",
              "label": "Picked surface",
              "fa": "سطح انتخابی"
            }
          ]
        },
        {
          "key": "level_id",
          "label": "Level",
          "fa": "تراز",
          "type": "level",
          "default": "ground",
          "section": "placement"
        },
        {
          "key": "z_offset",
          "label": "Level / surface offset",
          "fa": "آفست ارتفاع",
          "type": "length",
          "default": "0 mm",
          "section": "placement",
          "min": -100000
        },
        {
          "key": "rotation",
          "label": "Additional rotation (°)",
          "fa": "چرخش افزوده (درجه)",
          "type": "number",
          "default": 0,
          "section": "placement",
          "min": -360,
          "max": 360
        },
        {
          "key": "name",
          "label": "Object name",
          "fa": "نام آبجکت",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "mark",
          "label": "Mark / type code",
          "fa": "کد / مارک",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "tag",
          "label": "Tag (blank = automatic)",
          "fa": "تگ (خالی = خودکار)",
          "type": "text",
          "default": "",
          "section": "advanced"
        }
      ],
      "roles": [
        {
          "id": "structure",
          "label": "Structure",
          "fa": "سازه",
          "key": "material"
        }
      ],
      "hint": "Draw two endpoints. The cross-section is previewed relative to the baseline.",
      "faHint": "دو سر تیر را مشخص کنید؛ مقطع نسبت به خط مبنا پیش‌نمایش می‌شود."
    },
    {
      "id": "slab",
      "label": "Slab",
      "fa": "دال",
      "category": "structure",
      "mode": "rectangle",
      "fields": [
        {
          "key": "width",
          "label": "Width",
          "fa": "عرض",
          "type": "length",
          "default": "5000 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "depth",
          "label": "Depth",
          "fa": "عمق",
          "type": "length",
          "default": "3500 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "thickness",
          "label": "Thickness",
          "fa": "ضخامت",
          "type": "length",
          "default": "200 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "top_material",
          "label": "Top",
          "fa": "سطح بالا",
          "type": "material",
          "default": "Draupr Concrete - Structural",
          "section": "materials"
        },
        {
          "key": "underside_material",
          "label": "Underside",
          "fa": "زیر دال",
          "type": "material",
          "default": "Draupr Concrete - Structural",
          "section": "materials"
        },
        {
          "key": "edge_material",
          "label": "Edge",
          "fa": "لبه",
          "type": "material",
          "default": "Draupr Concrete - Structural",
          "section": "materials"
        },
        {
          "key": "placement_mode",
          "label": "Elevation source",
          "fa": "مبنای ارتفاع",
          "type": "select",
          "default": "level",
          "section": "placement",
          "options": [
            {
              "value": "level",
              "label": "Project level",
              "fa": "تراز پروژه"
            },
            {
              "value": "surface",
              "label": "Picked surface",
              "fa": "سطح انتخابی"
            }
          ]
        },
        {
          "key": "level_id",
          "label": "Level",
          "fa": "تراز",
          "type": "level",
          "default": "ground",
          "section": "placement"
        },
        {
          "key": "z_offset",
          "label": "Level / surface offset",
          "fa": "آفست ارتفاع",
          "type": "length",
          "default": "0 mm",
          "section": "placement",
          "min": -100000
        },
        {
          "key": "rotation",
          "label": "Additional rotation (°)",
          "fa": "چرخش افزوده (درجه)",
          "type": "number",
          "default": 0,
          "section": "placement",
          "min": -360,
          "max": 360
        },
        {
          "key": "name",
          "label": "Object name",
          "fa": "نام آبجکت",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "mark",
          "label": "Mark / type code",
          "fa": "کد / مارک",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "tag",
          "label": "Tag (blank = automatic)",
          "fa": "تگ (خالی = خودکار)",
          "type": "text",
          "default": "",
          "section": "advanced"
        }
      ],
      "roles": [
        {
          "id": "top",
          "label": "Top",
          "fa": "بالا",
          "key": "top_material"
        },
        {
          "id": "underside",
          "label": "Underside",
          "fa": "زیر",
          "key": "underside_material"
        },
        {
          "id": "edge",
          "label": "Edge",
          "fa": "لبه",
          "key": "edge_material"
        }
      ],
      "hint": "Use opposite corners, a rotated three-click rectangle, or a selected horizontal face.",
      "faHint": "دو گوشه، مستطیل چرخیده سه‌کلیک، یا وجه افقی انتخاب‌شده را به کار ببرید."
    },
    {
      "id": "grid",
      "label": "Grid",
      "fa": "گرید",
      "category": "structure",
      "mode": "point",
      "fields": [
        {
          "key": "layout_mode",
          "label": "Grid spacing mode",
          "fa": "حالت فاصله گرید",
          "type": "select",
          "default": "equal",
          "section": "geometry",
          "options": [
            {
              "value": "equal",
              "label": "Equal spacing",
              "fa": "فاصله مساوی"
            },
            {
              "value": "custom",
              "label": "Unequal bays",
              "fa": "دهانه‌های نامساوی"
            }
          ]
        },
        {
          "key": "bays_x",
          "label": "X bay widths",
          "fa": "عرض دهانه‌های X",
          "type": "text",
          "default": "3600 mm, 4200 mm, 3000 mm",
          "section": "geometry",
          "show": {
            "layout_mode": "custom"
          }
        },
        {
          "key": "bays_y",
          "label": "Y bay widths",
          "fa": "عرض دهانه‌های Y",
          "type": "text",
          "default": "3000 mm, 4500 mm",
          "section": "geometry",
          "show": {
            "layout_mode": "custom"
          }
        },
        {
          "key": "spacing_x",
          "label": "Spacing X",
          "fa": "فاصله X",
          "type": "length",
          "default": "3600 mm",
          "section": "geometry",
          "min": 0.5,
          "show": {
            "layout_mode": "equal"
          }
        },
        {
          "key": "spacing_y",
          "label": "Spacing Y",
          "fa": "فاصله Y",
          "type": "length",
          "default": "3000 mm",
          "section": "geometry",
          "min": 0.5,
          "show": {
            "layout_mode": "equal"
          }
        },
        {
          "key": "count_x",
          "label": "Axes in X",
          "fa": "محورها در X",
          "type": "integer",
          "default": 4,
          "section": "geometry",
          "min": 1,
          "max": 40,
          "show": {
            "layout_mode": "equal"
          }
        },
        {
          "key": "count_y",
          "label": "Axes in Y",
          "fa": "محورها در Y",
          "type": "integer",
          "default": 3,
          "section": "geometry",
          "min": 1,
          "max": 26,
          "show": {
            "layout_mode": "equal"
          }
        },
        {
          "key": "placement_mode",
          "label": "Elevation source",
          "fa": "مبنای ارتفاع",
          "type": "select",
          "default": "level",
          "section": "placement",
          "options": [
            {
              "value": "level",
              "label": "Project level",
              "fa": "تراز پروژه"
            },
            {
              "value": "surface",
              "label": "Picked surface",
              "fa": "سطح انتخابی"
            }
          ]
        },
        {
          "key": "level_id",
          "label": "Level",
          "fa": "تراز",
          "type": "level",
          "default": "ground",
          "section": "placement"
        },
        {
          "key": "z_offset",
          "label": "Level / surface offset",
          "fa": "آفست ارتفاع",
          "type": "length",
          "default": "0 mm",
          "section": "placement",
          "min": -100000
        },
        {
          "key": "rotation",
          "label": "Additional rotation (°)",
          "fa": "چرخش افزوده (درجه)",
          "type": "number",
          "default": 0,
          "section": "placement",
          "min": -360,
          "max": 360
        },
        {
          "key": "name",
          "label": "Object name",
          "fa": "نام آبجکت",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "mark",
          "label": "Mark / type code",
          "fa": "کد / مارک",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "tag",
          "label": "Tag (blank = automatic)",
          "fa": "تگ (خالی = خودکار)",
          "type": "text",
          "default": "",
          "section": "advanced"
        }
      ],
      "roles": [],
      "hint": "Click a grid origin. Use Equal spacing or enter comma-separated unequal bay widths such as 3600 mm, 4200 mm, 3000 mm.",
      "faHint": "مبدا گرید را کلیک کنید. فاصله مساوی یا عرض دهانه‌های نامساوی را با ویرگول وارد کنید."
    },
    {
      "id": "stair",
      "label": "Stair",
      "fa": "پله",
      "category": "architecture",
      "mode": "direction",
      "fields": [
        {
          "key": "sizing_mode",
          "label": "Sizing mode",
          "fa": "روش اندازه‌گذاری",
          "type": "select",
          "default": "steps",
          "section": "geometry",
          "options": [
            {
              "value": "steps",
              "label": "Step count + riser",
              "fa": "تعداد پله + رایزر"
            },
            {
              "value": "floor",
              "label": "Floor height + target riser",
              "fa": "ارتفاع طبقه + رایزر هدف"
            }
          ]
        },
        {
          "key": "floor_height",
          "label": "Floor height",
          "fa": "ارتفاع طبقه",
          "type": "length",
          "default": "3000 mm",
          "section": "geometry",
          "min": 0.5,
          "show": {
            "sizing_mode": "floor"
          }
        },
        {
          "key": "steps",
          "label": "Risers",
          "fa": "تعداد رایزر",
          "type": "integer",
          "default": 12,
          "section": "geometry",
          "min": 2,
          "max": 150,
          "show": {
            "sizing_mode": "steps"
          }
        },
        {
          "key": "riser",
          "label": "Riser / target riser",
          "fa": "رایزر / رایزر هدف",
          "type": "length",
          "default": "170 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "tread",
          "label": "Tread depth",
          "fa": "عمق کف پله",
          "type": "length",
          "default": "300 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "width",
          "label": "Flight width",
          "fa": "عرض بازو",
          "type": "length",
          "default": "1200 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "turn",
          "label": "Flight arrangement",
          "fa": "آرایش بازو",
          "type": "select",
          "default": "straight",
          "section": "geometry",
          "options": [
            {
              "value": "straight",
              "label": "Straight",
              "fa": "مستقیم"
            },
            {
              "value": "L",
              "label": "L with landing",
              "fa": "L با پاگرد"
            },
            {
              "value": "U",
              "label": "U-Shaped (Switchback)",
              "fa": "U شکل"
            },
            {
              "value": "winder",
              "label": "Winder",
              "fa": "پیچشی"
            },
            {
              "value": "spiral",
              "label": "Spiral",
              "fa": "مارپیچ"
            }
          ]
        },
        {
          "key": "construction",
          "label": "Construction",
          "fa": "سازه",
          "type": "select",
          "default": "solid",
          "section": "geometry",
          "options": [
            {
              "value": "solid",
              "label": "Solid (to floor)",
              "fa": "توپر تا کف"
            },
            {
              "value": "closed",
              "label": "Closed Riser + Stringer",
              "fa": "ریزر بسته با تیر"
            },
            {
              "value": "open",
              "label": "Open Riser (Floating)",
              "fa": "ریزر باز (شناور)"
            }
          ]
        },
        {
          "key": "landing_depth",
          "label": "Landing depth",
          "fa": "عمق پاگرد",
          "type": "length",
          "default": "1200 mm",
          "section": "geometry",
          "min": 0.5,
          "show": {
            "turn": "L"
          }
        },
        {
          "key": "tread_thickness",
          "label": "Tread finish thickness",
          "fa": "ضخامت کف پله",
          "type": "length",
          "default": "25 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "railing",
          "label": "Include railing",
          "fa": "نرده داشته باشد",
          "type": "boolean",
          "default": false,
          "section": "geometry"
        },
        {
          "key": "rail_height",
          "label": "Rail height",
          "fa": "ارتفاع نرده",
          "type": "length",
          "default": "900 mm",
          "section": "geometry",
          "min": 0.5,
          "show": {
            "railing": true
          }
        },
        {
          "key": "material",
          "label": "Structure / risers",
          "fa": "سازه / رایزر",
          "type": "material",
          "default": "Draupr Concrete - Structural",
          "section": "materials"
        },
        {
          "key": "tread_material",
          "label": "Treads",
          "fa": "کف پله",
          "type": "material",
          "default": "Draupr Timber - Oak",
          "section": "materials"
        },
        {
          "key": "rail_material",
          "label": "Railing",
          "fa": "نرده",
          "type": "material",
          "default": "Draupr Steel - Satin",
          "section": "materials"
        },
        {
          "key": "placement_mode",
          "label": "Elevation source",
          "fa": "مبنای ارتفاع",
          "type": "select",
          "default": "level",
          "section": "placement",
          "options": [
            {
              "value": "level",
              "label": "Project level",
              "fa": "تراز پروژه"
            },
            {
              "value": "surface",
              "label": "Picked surface",
              "fa": "سطح انتخابی"
            }
          ]
        },
        {
          "key": "level_id",
          "label": "Level",
          "fa": "تراز",
          "type": "level",
          "default": "ground",
          "section": "placement"
        },
        {
          "key": "z_offset",
          "label": "Level / surface offset",
          "fa": "آفست ارتفاع",
          "type": "length",
          "default": "0 mm",
          "section": "placement",
          "min": -100000
        },
        {
          "key": "rotation",
          "label": "Additional rotation (°)",
          "fa": "چرخش افزوده (درجه)",
          "type": "number",
          "default": 0,
          "section": "placement",
          "min": -360,
          "max": 360
        },
        {
          "key": "name",
          "label": "Object name",
          "fa": "نام آبجکت",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "mark",
          "label": "Mark / type code",
          "fa": "کد / مارک",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "tag",
          "label": "Tag (blank = automatic)",
          "fa": "تگ (خالی = خودکار)",
          "type": "text",
          "default": "",
          "section": "advanced"
        }
      ],
      "roles": [
        {
          "id": "structure",
          "label": "Structure",
          "fa": "سازه",
          "key": "material"
        },
        {
          "id": "tread",
          "label": "Treads",
          "fa": "کف پله",
          "key": "tread_material"
        },
        {
          "id": "railing",
          "label": "Railing",
          "fa": "نرده",
          "key": "rail_material"
        }
      ],
      "hint": "First click positions the stair; the second sets ascent direction. Comfort feedback is not a code-compliance certification.",
      "faHint": "کلیک اول محل و کلیک دوم جهت صعود است. بررسی راحتی به معنی تأیید آیین‌نامه نیست."
    },
    {
      "id": "roof",
      "label": "Roof",
      "fa": "سقف",
      "category": "architecture",
      "mode": "rectangle",
      "fields": [
        {
          "key": "style",
          "label": "Roof style",
          "fa": "نوع سقف",
          "type": "select",
          "default": "gable",
          "section": "geometry",
          "options": [
            {
              "value": "gable",
              "label": "Gable",
              "fa": "دو شیب"
            },
            {
              "value": "hip",
              "label": "Hip",
              "fa": "چهار شیب"
            },
            {
              "value": "flat",
              "label": "Flat",
              "fa": "تخت"
            },
            {
              "value": "shed",
              "label": "Shed / Skillion",
              "fa": "تک‌شیب"
            },
            {
              "value": "gambrel",
              "label": "Gambrel",
              "fa": "گامبرل"
            },
            {
              "value": "mansard",
              "label": "Mansard",
              "fa": "منصارد"
            }
          ]
        },
        {
          "key": "width",
          "label": "Footprint width",
          "fa": "عرض محدوده",
          "type": "length",
          "default": "5000 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "depth",
          "label": "Footprint depth",
          "fa": "عمق محدوده",
          "type": "length",
          "default": "4000 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "sizing_mode",
          "label": "Slope controlled by",
          "fa": "کنترل شیب",
          "type": "select",
          "default": "rise",
          "section": "geometry",
          "options": [
            {
              "value": "rise",
              "label": "Rise",
              "fa": "خیز"
            },
            {
              "value": "pitch",
              "label": "Pitch angle",
              "fa": "زاویه شیب"
            }
          ],
          "showNot": {
            "style": "flat"
          }
        },
        {
          "key": "rise",
          "label": "Rise",
          "fa": "خیز",
          "type": "length",
          "default": "1200 mm",
          "section": "geometry",
          "min": 0.5,
          "show": {
            "sizing_mode": "rise"
          },
          "showNot": {
            "style": "flat"
          }
        },
        {
          "key": "pitch_deg",
          "label": "Pitch (°)",
          "fa": "زاویه شیب",
          "type": "number",
          "default": 25,
          "section": "geometry",
          "min": 1,
          "max": 75,
          "show": {
            "sizing_mode": "pitch"
          },
          "showNot": {
            "style": "flat"
          }
        },
        {
          "key": "ridge_axis",
          "label": "Gable ridge direction",
          "fa": "جهت خط‌الرأس",
          "type": "select",
          "default": "y",
          "section": "geometry",
          "options": [
            {
              "value": "y",
              "label": "Along depth",
              "fa": "در راستای عمق"
            },
            {
              "value": "x",
              "label": "Along width",
              "fa": "در راستای عرض"
            }
          ],
          "show": {
            "style": "gable"
          }
        },
        {
          "key": "thickness",
          "label": "Roof thickness",
          "fa": "ضخامت سقف",
          "type": "length",
          "default": "180 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "overhang",
          "label": "Overhang",
          "fa": "پیش‌آمدگی",
          "type": "length",
          "default": "400 mm",
          "section": "geometry",
          "min": 0
        },
        {
          "key": "top_material",
          "label": "Top finish",
          "fa": "پوشش بالا",
          "type": "material",
          "default": "Draupr Timber - Oak",
          "section": "materials"
        },
        {
          "key": "underside_material",
          "label": "Underside",
          "fa": "زیر سقف",
          "type": "material",
          "default": "Draupr Finish - Soft Plaster",
          "section": "materials"
        },
        {
          "key": "edge_material",
          "label": "Edge / fascia",
          "fa": "لبه / فاشیا",
          "type": "material",
          "default": "Draupr Timber - Oak",
          "section": "materials"
        },
        {
          "key": "placement_mode",
          "label": "Elevation source",
          "fa": "مبنای ارتفاع",
          "type": "select",
          "default": "level",
          "section": "placement",
          "options": [
            {
              "value": "level",
              "label": "Project level",
              "fa": "تراز پروژه"
            },
            {
              "value": "surface",
              "label": "Picked surface",
              "fa": "سطح انتخابی"
            }
          ]
        },
        {
          "key": "level_id",
          "label": "Level",
          "fa": "تراز",
          "type": "level",
          "default": "ground",
          "section": "placement"
        },
        {
          "key": "z_offset",
          "label": "Level / surface offset",
          "fa": "آفست ارتفاع",
          "type": "length",
          "default": "0 mm",
          "section": "placement",
          "min": -100000
        },
        {
          "key": "rotation",
          "label": "Additional rotation (°)",
          "fa": "چرخش افزوده (درجه)",
          "type": "number",
          "default": 0,
          "section": "placement",
          "min": -360,
          "max": 360
        },
        {
          "key": "name",
          "label": "Object name",
          "fa": "نام آبجکت",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "mark",
          "label": "Mark / type code",
          "fa": "کد / مارک",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "tag",
          "label": "Tag (blank = automatic)",
          "fa": "تگ (خالی = خودکار)",
          "type": "text",
          "default": "",
          "section": "advanced"
        }
      ],
      "roles": [
        {
          "id": "top",
          "label": "Top",
          "fa": "بالا",
          "key": "top_material"
        },
        {
          "id": "underside",
          "label": "Underside",
          "fa": "زیر",
          "key": "underside_material"
        },
        {
          "id": "edge",
          "label": "Edge",
          "fa": "لبه",
          "key": "edge_material"
        }
      ],
      "hint": "Draw a footprint. Selected-face creation supports rectangular pitched roofs and polygonal flat roofs.",
      "faHint": "محدوده را رسم کنید؛ وجه انتخابی برای سقف شیب‌دار مستطیلی و سقف تخت چندضلعی پشتیبانی می‌شود."
    },
    {
      "id": "railing",
      "label": "Railing",
      "fa": "نرده",
      "category": "architecture",
      "mode": "line",
      "fields": [
        {
          "key": "preset",
          "label": "Railing preset",
          "fa": "پیش‌ساخته نرده",
          "type": "select",
          "default": "standard",
          "section": "geometry",
          "options": [
            {
              "value": "standard",
              "label": "Standard parametric",
              "fa": "پارامتریک استاندارد"
            },
            {
              "value": "local_metal_module",
              "label": "Local 01 · Modular Metal",
              "fa": "محلی ۰۱ · فلزی مدولار"
            },
            {
              "value": "local_turned_baluster",
              "label": "Local 02 · Turned Baluster",
              "fa": "محلی ۰۲ · پایه خراطی‌شده"
            },
            {
              "value": "local_classical_baluster",
              "label": "Local 03 · Classical Baluster",
              "fa": "محلی ۰۳ · پایه کلاسیک"
            },
            {
              "value": "modern_vertical_slim",
              "label": "Modern 01 · Slim Pickets",
              "fa": "Modern 01 · Slim Pickets"
            },
            {
              "value": "modern_vertical_bold",
              "label": "Modern 02 · Wide Pickets",
              "fa": "Modern 02 · Wide Pickets"
            },
            {
              "value": "modern_horizontal_5",
              "label": "Modern 03 · Five Rails",
              "fa": "Modern 03 · Five Rails"
            },
            {
              "value": "modern_horizontal_8",
              "label": "Modern 04 · Eight Rails",
              "fa": "Modern 04 · Eight Rails"
            },
            {
              "value": "modern_cable",
              "label": "Modern 05 · Cable Lines",
              "fa": "Modern 05 · Cable Lines"
            },
            {
              "value": "modern_glass_frameless",
              "label": "Modern 06 · Frameless Glass",
              "fa": "Modern 06 · Frameless Glass"
            },
            {
              "value": "modern_glass_posts",
              "label": "Modern 07 · Post Glass",
              "fa": "Modern 07 · Post Glass"
            },
            {
              "value": "modern_grid",
              "label": "Modern 08 · Square Grid",
              "fa": "Modern 08 · Square Grid"
            },
            {
              "value": "modern_cross",
              "label": "Modern 09 · Cross Panels",
              "fa": "Modern 09 · Cross Panels"
            },
            {
              "value": "modern_diamond",
              "label": "Modern 10 · Diamond Mesh",
              "fa": "Modern 10 · Diamond Mesh"
            },
            {
              "value": "classic_square",
              "label": "Classic 01 · Square Balusters",
              "fa": "Classic 01 · Square Balusters"
            },
            {
              "value": "classic_turned",
              "label": "Classic 02 · Turned Balusters",
              "fa": "Classic 02 · Turned Balusters"
            },
            {
              "value": "classic_double",
              "label": "Classic 03 · Paired Balusters",
              "fa": "Classic 03 · Paired Balusters"
            },
            {
              "value": "classic_arch",
              "label": "Classic 04 · Arcade",
              "fa": "Classic 04 · Arcade"
            },
            {
              "value": "classic_scroll",
              "label": "Classic 05 · Scrollwork",
              "fa": "Classic 05 · Scrollwork"
            },
            {
              "value": "classic_greek",
              "label": "Classic 06 · Greek Key",
              "fa": "Classic 06 · Greek Key"
            },
            {
              "value": "classic_spear",
              "label": "Classic 07 · Spearhead",
              "fa": "Classic 07 · Spearhead"
            },
            {
              "value": "classic_ring",
              "label": "Classic 08 · Ring Pickets",
              "fa": "Classic 08 · Ring Pickets"
            },
            {
              "value": "classic_cross_circle",
              "label": "Classic 09 · Cross and Ring",
              "fa": "Classic 09 · Cross and Ring"
            },
            {
              "value": "classic_diamond",
              "label": "Classic 10 · Ornamental Diamond",
              "fa": "Classic 10 · Ornamental Diamond"
            }
          ]
        },
        {
          "key": "ornament_thickness",
          "label": "Ornament thickness",
          "fa": "ضخامت تزئینات",
          "type": "length",
          "default": "12 mm",
          "min": 1,
          "max": 100,
          "section": "geometry",
          "showNot": {
            "preset": "standard"
          }
        },
        {
          "key": "length",
          "label": "Length",
          "fa": "طول",
          "type": "length",
          "default": "3000 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "height",
          "label": "Height",
          "fa": "ارتفاع",
          "type": "length",
          "default": "1000 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "post_spacing",
          "label": "Maximum post spacing",
          "fa": "بیشینه فاصله پایه",
          "type": "length",
          "default": "900 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "infill_spacing",
          "label": "Maximum infill spacing",
          "fa": "بیشینه فاصله اجزای میانی",
          "type": "length",
          "default": "120 mm",
          "min": 20,
          "max": 1000,
          "section": "geometry",
          "showNot": {
            "preset": "standard"
          }
        },
        {
          "key": "post_diameter",
          "label": "Post diameter",
          "fa": "قطر پایه",
          "type": "length",
          "default": "50 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "rail_width",
          "label": "Top rail width",
          "fa": "عرض دست‌انداز",
          "type": "length",
          "default": "50 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "rail_thickness",
          "label": "Top rail thickness",
          "fa": "ضخامت دست‌انداز",
          "type": "length",
          "default": "50 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "post_material",
          "label": "Posts",
          "fa": "پایه‌ها",
          "type": "material",
          "default": "Draupr Steel - Satin",
          "section": "materials"
        },
        {
          "key": "rail_material",
          "label": "Handrail",
          "fa": "دست‌انداز",
          "type": "material",
          "default": "Draupr Steel - Satin",
          "section": "materials"
        },
        {
          "key": "placement_mode",
          "label": "Elevation source",
          "fa": "مبنای ارتفاع",
          "type": "select",
          "default": "level",
          "section": "placement",
          "options": [
            {
              "value": "level",
              "label": "Project level",
              "fa": "تراز پروژه"
            },
            {
              "value": "surface",
              "label": "Picked surface",
              "fa": "سطح انتخابی"
            }
          ]
        },
        {
          "key": "level_id",
          "label": "Level",
          "fa": "تراز",
          "type": "level",
          "default": "ground",
          "section": "placement"
        },
        {
          "key": "z_offset",
          "label": "Level / surface offset",
          "fa": "آفست ارتفاع",
          "type": "length",
          "default": "0 mm",
          "section": "placement",
          "min": -100000
        },
        {
          "key": "rotation",
          "label": "Additional rotation (°)",
          "fa": "چرخش افزوده (درجه)",
          "type": "number",
          "default": 0,
          "section": "placement",
          "min": -360,
          "max": 360
        },
        {
          "key": "name",
          "label": "Object name",
          "fa": "نام آبجکت",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "mark",
          "label": "Mark / type code",
          "fa": "کد / مارک",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "tag",
          "label": "Tag (blank = automatic)",
          "fa": "تگ (خالی = خودکار)",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "infill",
          "label": "Infill",
          "fa": "پرکردن",
          "type": "select",
          "default": "posts",
          "section": "geometry",
          "options": [
            {
              "value": "posts",
              "label": "Posts",
              "fa": "ستونی"
            },
            {
              "value": "balusters",
              "label": "Balusters",
              "fa": "بالستر"
            },
            {
              "value": "glass",
              "label": "Glass Panel",
              "fa": "پنل شیشه"
            },
            {
              "value": "cable",
              "label": "Cable",
              "fa": "کابل"
            }
          ],
          "show": {
            "preset": "standard"
          }
        },
        {
          "key": "infill_material",
          "label": "Infill Material",
          "fa": "متریال پرکردن",
          "type": "material",
          "default": "Draupr Glass - Clear Blue",
          "section": "materials",
          "show": {
            "infill": "glass",
            "preset": "standard"
          }
        }
      ],
      "roles": [
        {
          "id": "post",
          "label": "Posts",
          "fa": "پایه",
          "key": "post_material"
        },
        {
          "id": "rail",
          "label": "Handrail",
          "fa": "دست‌انداز",
          "key": "rail_material"
        }
      ],
      "hint": "Preset geometry is fully parametric: member count follows actual path length and Maximum infill spacing; panel count follows Maximum post spacing.",
      "faHint": "هندسه پیش‌ساخته کاملاً پارامتریک است: تعداد اجزای میانی از طول واقعی مسیر و بیشینه فاصله اجزای میانی، و تعداد پنل‌ها از بیشینه فاصله پایه محاسبه می‌شود."
    },
    {
      "id": "louver",
      "label": "Louvers",
      "fa": "لوور",
      "category": "architecture",
      "mode": "line",
      "fields": [
        {
          "key": "width",
          "label": "Width",
          "fa": "عرض",
          "type": "length",
          "default": "2400 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "height",
          "label": "Array height",
          "fa": "ارتفاع آرایه",
          "type": "length",
          "default": "1800 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "count",
          "label": "Blade count",
          "fa": "تعداد تیغه",
          "type": "integer",
          "default": 8,
          "section": "geometry",
          "min": 1,
          "max": 300
        },
        {
          "key": "blade_depth",
          "label": "Blade depth",
          "fa": "عمق تیغه",
          "type": "length",
          "default": "160 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "blade_thickness",
          "label": "Blade thickness",
          "fa": "ضخامت تیغه",
          "type": "length",
          "default": "35 mm",
          "section": "geometry",
          "min": 0.5
        },
        {
          "key": "blade_angle",
          "label": "Blade angle (°)",
          "fa": "زاویه تیغه",
          "type": "number",
          "default": 0,
          "section": "geometry",
          "min": -85,
          "max": 85
        },
        {
          "key": "material",
          "label": "Blades",
          "fa": "تیغه‌ها",
          "type": "material",
          "default": "Draupr Mullion - Graphite",
          "section": "materials"
        },
        {
          "key": "placement_mode",
          "label": "Elevation source",
          "fa": "مبنای ارتفاع",
          "type": "select",
          "default": "level",
          "section": "placement",
          "options": [
            {
              "value": "level",
              "label": "Project level",
              "fa": "تراز پروژه"
            },
            {
              "value": "surface",
              "label": "Picked surface",
              "fa": "سطح انتخابی"
            }
          ]
        },
        {
          "key": "level_id",
          "label": "Level",
          "fa": "تراز",
          "type": "level",
          "default": "ground",
          "section": "placement"
        },
        {
          "key": "z_offset",
          "label": "Level / surface offset",
          "fa": "آفست ارتفاع",
          "type": "length",
          "default": "0 mm",
          "section": "placement",
          "min": -100000
        },
        {
          "key": "rotation",
          "label": "Additional rotation (°)",
          "fa": "چرخش افزوده (درجه)",
          "type": "number",
          "default": 0,
          "section": "placement",
          "min": -360,
          "max": 360
        },
        {
          "key": "name",
          "label": "Object name",
          "fa": "نام آبجکت",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "mark",
          "label": "Mark / type code",
          "fa": "کد / مارک",
          "type": "text",
          "default": "",
          "section": "advanced"
        },
        {
          "key": "tag",
          "label": "Tag (blank = automatic)",
          "fa": "تگ (خالی = خودکار)",
          "type": "text",
          "default": "",
          "section": "advanced"
        }
      ],
      "roles": [
        {
          "id": "blade",
          "label": "Blades",
          "fa": "تیغه",
          "key": "material"
        }
      ],
      "hint": "Draw a baseline. Blade depth, thickness and tilt remain editable.",
      "faHint": "خط مبنا را رسم کنید؛ عمق، ضخامت و زاویه تیغه‌ها قابل ویرایش می‌مانند."
    },
    {
      "id": "ramp",
      "label": "Ramp",
      "fa": "رمپ",
      "category": "architecture",
      "mode": "direction",
      "fields": [
        {
          "key": "length",
          "label": "Length",
          "fa": "طول",
          "type": "length",
          "default": "6000 mm",
          "min": 0,
          "max": 60000,
          "section": "geometry"
        },
        {
          "key": "width",
          "label": "Width",
          "fa": "عرض",
          "type": "length",
          "default": "1200 mm",
          "min": 0,
          "max": 6000,
          "section": "geometry"
        },
        {
          "key": "rise",
          "label": "Total Rise",
          "fa": "ارتفاع کل",
          "type": "length",
          "default": "600 mm",
          "min": 0,
          "max": 6000,
          "section": "geometry"
        },
        {
          "key": "rails",
          "label": "Handrails",
          "fa": "نرده",
          "type": "boolean",
          "default": true,
          "section": "geometry"
        },
        {
          "key": "rail_height",
          "label": "Rail Height",
          "fa": "ارتفاع نرده",
          "type": "length",
          "default": "900 mm",
          "min": 0,
          "max": 2000,
          "section": "geometry"
        },
        {
          "key": "material",
          "label": "Material",
          "fa": "متریال",
          "type": "material",
          "default": "Draupr Concrete - Structural",
          "section": "materials"
        },
        {
          "key": "rail_material",
          "label": "Rail Material",
          "fa": "متریال نرده",
          "type": "material",
          "default": "Draupr Steel - Satin",
          "section": "materials"
        },
        {
          "key": "placement_mode",
          "label": "Elevation source",
          "fa": "مبنای ارتفاع",
          "type": "select",
          "default": "level",
          "section": "placement",
          "options": [
            {
              "value": "level",
              "label": "Project level",
              "fa": "تراز پروژه"
            },
            {
              "value": "surface",
              "label": "Picked surface",
              "fa": "سطح انتخابی"
            }
          ]
        },
        {
          "key": "level_id",
          "label": "Level",
          "fa": "تراز",
          "type": "level",
          "default": "ground",
          "section": "placement"
        },
        {
          "key": "z_offset",
          "label": "Level / surface offset",
          "fa": "آفست ارتفاع",
          "type": "length",
          "default": "0 mm",
          "section": "placement",
          "min": -100000
        },
        {
          "key": "rotation",
          "label": "Additional rotation (°)",
          "fa": "چرخش افزوده (درجه)",
          "type": "number",
          "default": 0,
          "section": "placement",
          "min": -360,
          "max": 360
        },
        {
          "key": "name",
          "label": "Object name",
          "fa": "نام آبجکت",
          "type": "text",
          "default": "Ramp",
          "section": "advanced"
        },
        {
          "key": "mark",
          "label": "Mark / type code",
          "fa": "کد / مارک",
          "type": "text",
          "default": "RA",
          "section": "advanced"
        },
        {
          "key": "tag",
          "label": "Tag (blank = automatic)",
          "fa": "تگ (خالی = خودکار)",
          "type": "text",
          "default": "",
          "section": "advanced"
        }
      ],
      "roles": [
        {
          "id": "structure",
          "label": "Ramp",
          "fa": "رمپ",
          "key": "material"
        },
        {
          "id": "railing",
          "label": "Rails",
          "fa": "نرده",
          "key": "rail_material"
        }
      ],
      "hint": "Click position, then the uphill direction; length is taken from the drawn line.",
      "faHint": "محل را کلیک کنید، سپس جهت سربالایی؛ طول از خط ترسیم‌شده گرفته می‌شود."
    },
    {
      "id": "skylight",
      "label": "Skylight",
      "fa": "اسکای‌لایت",
      "category": "architecture",
      "mode": "rectangle",
      "fields": [
        {
          "key": "width",
          "label": "Width",
          "fa": "عرض",
          "type": "length",
          "default": "1200 mm",
          "min": 0,
          "max": 6000,
          "section": "geometry"
        },
        {
          "key": "depth",
          "label": "Depth",
          "fa": "عمق",
          "type": "length",
          "default": "1200 mm",
          "min": 0,
          "max": 6000,
          "section": "geometry"
        },
        {
          "key": "height",
          "label": "Curb Height",
          "fa": "ارتفاع لبه",
          "type": "length",
          "default": "150 mm",
          "min": 0,
          "max": 1000,
          "section": "geometry"
        },
        {
          "key": "pitch",
          "label": "Lid Pitch (deg)",
          "fa": "شیب درب (درجه)",
          "type": "number",
          "default": "15",
          "min": 0,
          "max": 45,
          "section": "geometry"
        },
        {
          "key": "frame",
          "label": "Frame Width",
          "fa": "عرض قاب",
          "type": "length",
          "default": "60 mm",
          "min": 0,
          "max": 300,
          "section": "geometry"
        },
        {
          "key": "frame_material",
          "label": "Frame Material",
          "fa": "متریال قاب",
          "type": "material",
          "default": "Draupr Mullion - Graphite",
          "section": "materials"
        },
        {
          "key": "glass_material",
          "label": "Glass Material",
          "fa": "متریال شیشه",
          "type": "material",
          "default": "Draupr Glass - Clear Blue",
          "section": "materials"
        },
        {
          "key": "placement_mode",
          "label": "Elevation source",
          "fa": "مبنای ارتفاع",
          "type": "select",
          "default": "level",
          "section": "placement",
          "options": [
            {
              "value": "level",
              "label": "Project level",
              "fa": "تراز پروژه"
            },
            {
              "value": "surface",
              "label": "Picked surface",
              "fa": "سطح انتخابی"
            }
          ]
        },
        {
          "key": "level_id",
          "label": "Level",
          "fa": "تراز",
          "type": "level",
          "default": "ground",
          "section": "placement"
        },
        {
          "key": "z_offset",
          "label": "Level / surface offset",
          "fa": "آفست ارتفاع",
          "type": "length",
          "default": "0 mm",
          "section": "placement",
          "min": -100000
        },
        {
          "key": "rotation",
          "label": "Additional rotation (°)",
          "fa": "چرخش افزوده (درجه)",
          "type": "number",
          "default": 0,
          "section": "placement",
          "min": -360,
          "max": 360
        },
        {
          "key": "name",
          "label": "Object name",
          "fa": "نام آبجکت",
          "type": "text",
          "default": "Skylight",
          "section": "advanced"
        },
        {
          "key": "mark",
          "label": "Mark / type code",
          "fa": "کد / مارک",
          "type": "text",
          "default": "SK",
          "section": "advanced"
        },
        {
          "key": "tag",
          "label": "Tag (blank = automatic)",
          "fa": "تگ (خالی = خودکار)",
          "type": "text",
          "default": "",
          "section": "advanced"
        }
      ],
      "roles": [
        {
          "id": "frame",
          "label": "Frame",
          "fa": "قاب",
          "key": "frame_material"
        },
        {
          "id": "glass",
          "label": "Glass",
          "fa": "شیشه",
          "key": "glass_material"
        }
      ],
      "hint": "Drag a rectangle on a roof face; the curb sits on the surface and the glass lid tilts to the pitch. Choose On a roof in the mode list to place and cut into a roof face.",
      "faHint": "مستطیلی روی سطح سقف بکشید؛ لبه روی سطح قرار می‌گیرد و درب شیشه‌ای با شیب تنظیم می‌شود. برای قرارگیری و برش روی سقف، حالت On a roof را انتخاب کنید."
    },
    {
      "id": "dormer",
      "label": "Dormer",
      "fa": "دورمر",
      "category": "architecture",
      "mode": "rectangle",
      "fields": [
        {
          "key": "dormer_type",
          "label": "Dormer Type",
          "fa": "نوع دورمر",
          "type": "select",
          "default": "gabled",
          "section": "geometry",
          "options": [
            {
              "value": "gabled",
              "label": "Gabled Dormer",
              "fa": "دورمر شیروانی"
            },
            {
              "value": "hipped",
              "label": "Hipped Dormer",
              "fa": "دورمر چهارشیب"
            },
            {
              "value": "shed",
              "label": "Shed Dormer",
              "fa": "دورمر یک‌شیب"
            },
            {
              "value": "eyebrow",
              "label": "Eyebrow Dormer",
              "fa": "دورمر ابرویی"
            },
            {
              "value": "segmental",
              "label": "Segmental Arch Dormer",
              "fa": "دورمر قوس کم‌خیز"
            },
            {
              "value": "barrel",
              "label": "Barrel Roof Dormer",
              "fa": "دورمر بشکه‌ای"
            },
            {
              "value": "flat",
              "label": "Flat Roof Dormer",
              "fa": "دورمر تخت"
            },
            {
              "value": "pointed",
              "label": "Pointed Dormer",
              "fa": "دورمر نوک‌تیز"
            },
            {
              "value": "trapezoidal",
              "label": "Trapezoidal Dormer",
              "fa": "دورمر ذوزنقه‌ای"
            }
          ]
        },
        {
          "key": "width",
          "label": "Width",
          "fa": "عرض",
          "type": "length",
          "default": "1800 mm",
          "min": 0,
          "max": 12000,
          "section": "geometry"
        },
        {
          "key": "depth",
          "label": "Footprint Depth",
          "fa": "عمق واقعی محدوده",
          "type": "length",
          "default": "1850 mm",
          "min": 0,
          "max": 10000,
          "section": "geometry"
        },
        {
          "key": "height",
          "label": "Template Wall Height",
          "fa": "ارتفاع دیوار الگو",
          "type": "length",
          "default": "1350 mm",
          "min": 0,
          "max": 6000,
          "section": "geometry"
        },
        {
          "key": "rise",
          "label": "Template Roof Height",
          "fa": "ارتفاع سقف الگو",
          "type": "length",
          "default": "805 mm",
          "min": 0,
          "max": 3000,
          "section": "geometry"
        },
        {
          "key": "thickness",
          "label": "Roof Thickness",
          "fa": "ضخامت سقف",
          "type": "length",
          "default": "45 mm",
          "min": 0,
          "max": 300,
          "section": "geometry"
        },
        {
          "key": "window",
          "label": "Front Window",
          "fa": "پنجره جلویی",
          "type": "boolean",
          "default": true,
          "section": "geometry"
        },
        {
          "key": "wall_material",
          "label": "Wall Material",
          "fa": "متریال دیوار",
          "type": "material",
          "default": "Draupr Finish - Soft Plaster",
          "section": "materials"
        },
        {
          "key": "roof_material",
          "label": "Roof Material",
          "fa": "متریال سقف",
          "type": "material",
          "default": "Draupr Roofing - Charcoal Shingle",
          "section": "materials"
        },
        {
          "key": "frame_material",
          "label": "Frame Material",
          "fa": "متریال قاب",
          "type": "material",
          "default": "Draupr Mullion - Graphite",
          "section": "materials"
        },
        {
          "key": "trim_material",
          "label": "Trim and Fascia Material",
          "fa": "متریال تزئینات و فاشیا",
          "type": "material",
          "default": "Draupr Trim - Warm White",
          "section": "materials"
        },
        {
          "key": "glass_material",
          "label": "Glass Material",
          "fa": "متریال شیشه",
          "type": "material",
          "default": "Draupr Glass - Clear Blue",
          "section": "materials"
        },
        {
          "key": "placement_mode",
          "label": "Elevation source",
          "fa": "مبنای ارتفاع",
          "type": "select",
          "default": "level",
          "section": "placement",
          "options": [
            {
              "value": "level",
              "label": "Project level",
              "fa": "تراز پروژه"
            },
            {
              "value": "surface",
              "label": "Picked surface",
              "fa": "سطح انتخابی"
            }
          ]
        },
        {
          "key": "level_id",
          "label": "Level",
          "fa": "تراز",
          "type": "level",
          "default": "ground",
          "section": "placement"
        },
        {
          "key": "z_offset",
          "label": "Level / surface offset",
          "fa": "آفست ارتفاع",
          "type": "length",
          "default": "0 mm",
          "section": "placement",
          "min": -100000
        },
        {
          "key": "rotation",
          "label": "Additional rotation (°)",
          "fa": "چرخش افزوده (درجه)",
          "type": "number",
          "default": 0,
          "section": "placement",
          "min": -360,
          "max": 360
        },
        {
          "key": "name",
          "label": "Object name",
          "fa": "نام آبجکت",
          "type": "text",
          "default": "Dormer",
          "section": "advanced"
        },
        {
          "key": "mark",
          "label": "Mark / type code",
          "fa": "کد / مارک",
          "type": "text",
          "default": "DO",
          "section": "advanced"
        },
        {
          "key": "tag",
          "label": "Tag (blank = automatic)",
          "fa": "تگ (خالی = خودکار)",
          "type": "text",
          "default": "",
          "section": "advanced"
        }
      ],
      "roles": [
        {
          "id": "wall",
          "label": "Wall",
          "fa": "دیوار",
          "key": "wall_material"
        },
        {
          "id": "roof",
          "label": "Roof",
          "fa": "سقف",
          "key": "roof_material"
        },
        {
          "id": "frame",
          "label": "Window Frame",
          "fa": "قاب پنجره",
          "key": "frame_material"
        },
        {
          "id": "trim",
          "label": "Trim and Fascia",
          "fa": "تزئینات و فاشیا",
          "key": "trim_material"
        },
        {
          "id": "glass",
          "label": "Window Glass",
          "fa": "شیشه پنجره",
          "key": "glass_material"
        }
      ],
      "hint": "Draw the real footprint on a roof. All nine Dormer types use roof-hosted parametric geometry, a physical roof opening, adaptive front window, and separate frame and trim finishes.",
      "faHint": "محدوده واقعی را روی سقف رسم کنید. هر نه نوع دورمر از هندسه پارامتریک متصل به سقف، بازشوی واقعی، پنجره جلویی تطبیقی و متریال‌های جداگانه قاب و تزئینات استفاده می‌کنند."
    },
    {
      "id": "molding",
      "label": "Molding Run",
      "fa": "نوار تزئینی",
      "category": "architecture",
      "mode": "path",
      "fields": [
        {
          "key": "profile",
          "label": "Profile",
          "fa": "پروفیل",
          "type": "select",
          "default": "baseboard",
          "section": "geometry",
          "options": [
            {
              "value": "baseboard",
              "label": "Baseboard / Skirting",
              "fa": "قرنیز"
            },
            {
              "value": "crown",
              "label": "Crown",
              "fa": "تاجی"
            },
            {
              "value": "cove",
              "label": "Cove",
              "fa": "مقعر"
            },
            {
              "value": "chair_rail",
              "label": "Chair Rail",
              "fa": "نیم‌نوار"
            },
            {
              "value": "custom",
              "label": "Custom (from face)",
              "fa": "سفارشی (از وجه)"
            },
            {
              "value": "ip_500",
              "label": "IP-500",
              "fa": "IP-500"
            },
            {
              "value": "ip_501",
              "label": "IP-501",
              "fa": "IP-501"
            },
            {
              "value": "ip_502",
              "label": "IP-502",
              "fa": "IP-502"
            },
            {
              "value": "ip_503",
              "label": "IP-503",
              "fa": "IP-503"
            },
            {
              "value": "ip_504",
              "label": "IP-504",
              "fa": "IP-504"
            },
            {
              "value": "ip_505",
              "label": "IP-505",
              "fa": "IP-505"
            },
            {
              "value": "ip_506",
              "label": "IP-506",
              "fa": "IP-506"
            },
            {
              "value": "ip_507",
              "label": "IP-507",
              "fa": "IP-507"
            },
            {
              "value": "ip_508",
              "label": "IP-508",
              "fa": "IP-508"
            },
            {
              "value": "ip_509",
              "label": "IP-509",
              "fa": "IP-509"
            },
            {
              "value": "ip_510",
              "label": "IP-510",
              "fa": "IP-510"
            },
            {
              "value": "ip_511",
              "label": "IP-511",
              "fa": "IP-511"
            },
            {
              "value": "ip_513",
              "label": "IP-513",
              "fa": "IP-513"
            },
            {
              "value": "ip_514",
              "label": "IP-514",
              "fa": "IP-514"
            },
            {
              "value": "ip_515",
              "label": "IP-515",
              "fa": "IP-515"
            },
            {
              "value": "ip_516",
              "label": "IP-516",
              "fa": "IP-516"
            },
            {
              "value": "ip_517",
              "label": "IP-517",
              "fa": "IP-517"
            },
            {
              "value": "ip_518",
              "label": "IP-518",
              "fa": "IP-518"
            },
            {
              "value": "ip_519",
              "label": "IP-519",
              "fa": "IP-519"
            },
            {
              "value": "ip_520",
              "label": "IP-520",
              "fa": "IP-520"
            },
            {
              "value": "ip_521",
              "label": "IP-521",
              "fa": "IP-521"
            },
            {
              "value": "ip_522",
              "label": "IP-522",
              "fa": "IP-522"
            },
            {
              "value": "ip_523",
              "label": "IP-523",
              "fa": "IP-523"
            },
            {
              "value": "ip_524",
              "label": "IP-524",
              "fa": "IP-524"
            },
            {
              "value": "ip_525",
              "label": "IP-525",
              "fa": "IP-525"
            },
            {
              "value": "ip_527",
              "label": "IP-527",
              "fa": "IP-527"
            },
            {
              "value": "ip_529",
              "label": "IP-529",
              "fa": "IP-529"
            },
            {
              "value": "ip_530",
              "label": "IP-530",
              "fa": "IP-530"
            },
            {
              "value": "ip_534",
              "label": "IP-534",
              "fa": "IP-534"
            },
            {
              "value": "ip_535",
              "label": "IP-535",
              "fa": "IP-535"
            },
            {
              "value": "ip_602",
              "label": "IP-602",
              "fa": "IP-602"
            },
            {
              "value": "ip_606",
              "label": "IP-606",
              "fa": "IP-606"
            },
            {
              "value": "ip_616",
              "label": "IP-616",
              "fa": "IP-616"
            },
            {
              "value": "ip_617",
              "label": "IP-617",
              "fa": "IP-617"
            },
            {
              "value": "ip_618",
              "label": "IP-618",
              "fa": "IP-618"
            }
          ]
        },
        {
          "key": "profile_anchor",
          "label": "Insertion point",
          "fa": "نقطه درج",
          "type": "select",
          "default": "back_top",
          "section": "geometry",
          "options": [
            {
              "value": "back_top",
              "label": "Back top · wall/ceiling",
              "fa": "پشت بالا · دیوار/سقف"
            },
            {
              "value": "back_bottom",
              "label": "Back bottom · wall/floor",
              "fa": "پشت پایین · دیوار/کف"
            },
            {
              "value": "front_top",
              "label": "Front top",
              "fa": "جلو بالا"
            },
            {
              "value": "front_bottom",
              "label": "Front bottom",
              "fa": "جلو پایین"
            },
            {
              "value": "center",
              "label": "Profile center",
              "fa": "مرکز پروفیل"
            }
          ]
        },
        {
          "key": "preserve_profile_ratio",
          "label": "Preserve profile proportions",
          "fa": "حفظ تناسب پروفیل",
          "type": "boolean",
          "default": true,
          "section": "geometry"
        },
        {
          "key": "height",
          "label": "Height",
          "fa": "ارتفاع",
          "type": "length",
          "default": "100 mm",
          "min": 0,
          "max": 1000,
          "section": "geometry"
        },
        {
          "key": "projection",
          "label": "Projection",
          "fa": "پیش‌آمدگی",
          "type": "length",
          "default": "25 mm",
          "min": 0,
          "max": 300,
          "section": "geometry",
          "showNot": {
            "preserve_profile_ratio": true
          }
        },
        {
          "key": "material",
          "label": "Material",
          "fa": "متریال",
          "type": "material",
          "default": "Draupr Finish - Soft Plaster",
          "section": "materials"
        },
        {
          "key": "flip_profile",
          "label": "Flip profile side",
          "fa": "برعکس کردن سمت پروفیل",
          "type": "boolean",
          "default": false,
          "section": "placement"
        },
        {
          "key": "profile_rotation",
          "label": "Profile rotation (°)",
          "fa": "چرخش پروفیل (درجه)",
          "type": "number",
          "default": 0,
          "min": -360,
          "max": 360,
          "section": "placement"
        },
        {
          "key": "placement_mode",
          "label": "Elevation source",
          "fa": "مبنای ارتفاع",
          "type": "select",
          "default": "level",
          "section": "placement",
          "options": [
            {
              "value": "level",
              "label": "Project level",
              "fa": "تراز پروژه"
            },
            {
              "value": "surface",
              "label": "Picked surface",
              "fa": "سطح انتخابی"
            }
          ]
        },
        {
          "key": "level_id",
          "label": "Level",
          "fa": "تراز",
          "type": "level",
          "default": "ground",
          "section": "placement"
        },
        {
          "key": "z_offset",
          "label": "Level / surface offset",
          "fa": "آفست ارتفاع",
          "type": "length",
          "default": "0 mm",
          "section": "placement",
          "min": -100000
        },
        {
          "key": "rotation",
          "label": "Additional rotation (°)",
          "fa": "چرخش افزوده (درجه)",
          "type": "number",
          "default": 0,
          "section": "placement",
          "min": -360,
          "max": 360
        },
        {
          "key": "name",
          "label": "Object name",
          "fa": "نام آبجکت",
          "type": "text",
          "default": "Molding Run",
          "section": "advanced"
        },
        {
          "key": "mark",
          "label": "Mark / type code",
          "fa": "کد / مارک",
          "type": "text",
          "default": "MO",
          "section": "advanced"
        },
        {
          "key": "tag",
          "label": "Tag (blank = automatic)",
          "fa": "تگ (خالی = خودکار)",
          "type": "text",
          "default": "",
          "section": "advanced"
        }
      ],
      "roles": [
        {
          "id": "molding",
          "label": "Molding",
          "fa": "نوار",
          "key": "material"
        }
      ],
      "hint": "Catalog profiles use exact straight wall and ceiling contact edges. Only the exposed front boundary keeps decorative curves and steps. Back top remains the default insertion point.",
      "faHint": "لبه‌های تماس پروفیل‌های آماده با دیوار و سقف کاملاً مستقیم هستند و فقط نمای بیرونی دارای منحنی و پله است. نقطه درج پیش‌فرض پشت بالا است."
    }
  ],
  "categories": [
    {
      "id": "envelope",
      "label": "Envelope",
      "fa": "پوسته"
    },
    {
      "id": "structure",
      "label": "Structure",
      "fa": "سازه"
    },
    {
      "id": "architecture",
      "label": "Architecture",
      "fa": "معماری"
    }
  ],
  "release": "3.1.15"
};
