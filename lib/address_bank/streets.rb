module AddressBank
  # Approximate street segments in and around Toronto. Each entry gives the
  # printed name, the forward sortation area, the segment endpoints, and the
  # civic number range. Numbers are interpolated along the segment; odd and
  # even numbers sit on opposite sides. Good enough to place a pin on the right
  # block, which is all the demo needs.
  module Streets
    Segment = Struct.new(:name, :fsa, :from, :to, :numbers, :city, keyword_init: true)

    ALL = [
    # Queen West and Trinity Bellwoods
    Segment.new(name: "Palmerston Ave", fsa: "M6J", from: [43.6470, -79.4110], to: [43.6560, -79.4118], numbers: 2..600),
    Segment.new(name: "Euclid Ave", fsa: "M6J", from: [43.6462, -79.4081], to: [43.6555, -79.4090], numbers: 2..560),
    Segment.new(name: "Manning Ave", fsa: "M6J", from: [43.6458, -79.4095], to: [43.6552, -79.4103], numbers: 2..540),
    Segment.new(name: "Claremont St", fsa: "M6J", from: [43.6465, -79.4066], to: [43.6520, -79.4072], numbers: 2..260),
    Segment.new(name: "Bellwoods Ave", fsa: "M6J", from: [43.6458, -79.4130], to: [43.6512, -79.4137], numbers: 2..200),
    Segment.new(name: "Crawford St", fsa: "M6J", from: [43.6450, -79.4160], to: [43.6555, -79.4170], numbers: 2..700),
    Segment.new(name: "Shaw St", fsa: "M6J", from: [43.6445, -79.4185], to: [43.6560, -79.4195], numbers: 2..800),
    Segment.new(name: "Givins St", fsa: "M6J", from: [43.6440, -79.4198], to: [43.6478, -79.4202], numbers: 2..120),
    Segment.new(name: "Ossington Ave", fsa: "M6J", from: [43.6435, -79.4210], to: [43.6640, -79.4230], numbers: 2..1100),
    Segment.new(name: "Dovercourt Rd", fsa: "M6J", from: [43.6425, -79.4240], to: [43.6650, -79.4265], numbers: 2..1200),
    Segment.new(name: "Argyle St", fsa: "M6J", from: [43.6455, -79.4125], to: [43.6445, -79.4235], numbers: 2..300),
    Segment.new(name: "Queen St W", fsa: "M5V", from: [43.6486, -79.3960], to: [43.6466, -79.4112], numbers: 300..760),
    Segment.new(name: "Queen St W", fsa: "M6J", from: [43.6466, -79.4114], to: [43.6415, -79.4310], numbers: 761..1500),
    Segment.new(name: "Dundas St W", fsa: "M6J", from: [43.6530, -79.3990], to: [43.6495, -79.4320], numbers: 500..1500),
    Segment.new(name: "College St", fsa: "M6G", from: [43.6575, -79.4000], to: [43.6540, -79.4320], numbers: 400..1200),
    Segment.new(name: "Bathurst St", fsa: "M5T", from: [43.6440, -79.4030], to: [43.6660, -79.4110], numbers: 300..1000),
    # Downtown west
    Segment.new(name: "King St W", fsa: "M5V", from: [43.6485, -79.3830], to: [43.6440, -79.4000], numbers: 100..700),
    Segment.new(name: "Adelaide St W", fsa: "M5V", from: [43.6500, -79.3820], to: [43.6460, -79.3990], numbers: 100..600),
    Segment.new(name: "Richmond St W", fsa: "M5V", from: [43.6505, -79.3830], to: [43.6470, -79.3990], numbers: 100..600),
    Segment.new(name: "Spadina Ave", fsa: "M5V", from: [43.6420, -79.3945], to: [43.6580, -79.4000], numbers: 100..700),
    Segment.new(name: "Peter St", fsa: "M5V", from: [43.6455, -79.3910], to: [43.6490, -79.3922], numbers: 1..200),
    Segment.new(name: "Portland St", fsa: "M5V", from: [43.6440, -79.4000], to: [43.6475, -79.4010], numbers: 1..200),
    Segment.new(name: "Augusta Ave", fsa: "M5T", from: [43.6520, -79.4010], to: [43.6560, -79.4020], numbers: 1..300),
    Segment.new(name: "Baldwin St", fsa: "M5T", from: [43.6555, -79.3985], to: [43.6548, -79.4030], numbers: 1..200),
    # Little Italy and the Annex
    Segment.new(name: "Harbord St", fsa: "M6G", from: [43.6620, -79.4000], to: [43.6600, -79.4200], numbers: 1..500),
    Segment.new(name: "Clinton St", fsa: "M6G", from: [43.6540, -79.4145], to: [43.6640, -79.4160], numbers: 1..500),
    Segment.new(name: "Grace St", fsa: "M6G", from: [43.6540, -79.4160], to: [43.6640, -79.4172], numbers: 1..500),
    Segment.new(name: "Beatrice St", fsa: "M6G", from: [43.6545, -79.4175], to: [43.6620, -79.4185], numbers: 1..300),
    Segment.new(name: "Montrose Ave", fsa: "M6G", from: [43.6545, -79.4190], to: [43.6650, -79.4205], numbers: 1..600),
    Segment.new(name: "Bloor St W", fsa: "M6G", from: [43.6650, -79.4050], to: [43.6600, -79.4500], numbers: 500..1500),
    Segment.new(name: "Dupont St", fsa: "M6G", from: [43.6730, -79.4000], to: [43.6680, -79.4500], numbers: 100..1400),
    Segment.new(name: "Avenue Rd", fsa: "M5R", from: [43.6700, -79.3960], to: [43.7100, -79.4050], numbers: 100..1000),
    # Parkdale and Roncesvalles
    Segment.new(name: "Roncesvalles Ave", fsa: "M6R", from: [43.6390, -79.4480], to: [43.6520, -79.4500], numbers: 1..500),
    Segment.new(name: "Sorauren Ave", fsa: "M6R", from: [43.6435, -79.4430], to: [43.6530, -79.4450], numbers: 1..400),
    Segment.new(name: "Dufferin St", fsa: "M6K", from: [43.6395, -79.4315], to: [43.6640, -79.4360], numbers: 1..1300),
    Segment.new(name: "Lansdowne Ave", fsa: "M6K", from: [43.6420, -79.4400], to: [43.6640, -79.4440], numbers: 1..1200),
    Segment.new(name: "Dunn Ave", fsa: "M6K", from: [43.6350, -79.4360], to: [43.6395, -79.4370], numbers: 1..250),
    Segment.new(name: "Jameson Ave", fsa: "M6K", from: [43.6345, -79.4390], to: [43.6390, -79.4400], numbers: 1..250),
    # East end
    Segment.new(name: "Queen St E", fsa: "M4M", from: [43.6535, -79.3560], to: [43.6660, -79.3160], numbers: 600..1900),
    Segment.new(name: "Carlaw Ave", fsa: "M4M", from: [43.6580, -79.3410], to: [43.6720, -79.3440], numbers: 1..500),
    Segment.new(name: "Pape Ave", fsa: "M4M", from: [43.6600, -79.3385], to: [43.6790, -79.3450], numbers: 1..900),
    Segment.new(name: "Logan Ave", fsa: "M4M", from: [43.6595, -79.3440], to: [43.6760, -79.3480], numbers: 1..700),
    Segment.new(name: "Jones Ave", fsa: "M4M", from: [43.6620, -79.3340], to: [43.6780, -79.3390], numbers: 1..700),
    Segment.new(name: "Broadview Ave", fsa: "M4K", from: [43.6560, -79.3520], to: [43.6790, -79.3590], numbers: 1..1000),
    Segment.new(name: "Danforth Ave", fsa: "M4K", from: [43.6765, -79.3560], to: [43.6800, -79.3360], numbers: 100..800),
    Segment.new(name: "Danforth Ave", fsa: "M4J", from: [43.6800, -79.3358], to: [43.6840, -79.3150], numbers: 801..1500),
    Segment.new(name: "Woodbine Ave", fsa: "M4L", from: [43.6665, -79.3095], to: [43.6900, -79.3150], numbers: 1..1200),
    Segment.new(name: "Kingston Rd", fsa: "M4L", from: [43.6690, -79.3100], to: [43.6800, -79.2800], numbers: 100..1200),
    # Midtown
    Segment.new(name: "Yonge St", fsa: "M4S", from: [43.6700, -79.3860], to: [43.7050, -79.3980], numbers: 700..2600),
    Segment.new(name: "Mount Pleasant Rd", fsa: "M4S", from: [43.6890, -79.3830], to: [43.7100, -79.3900], numbers: 400..1000),
    Segment.new(name: "Bayview Ave", fsa: "M4G", from: [43.6800, -79.3700], to: [43.7100, -79.3760], numbers: 1000..1800),
    Segment.new(name: "Eglinton Ave W", fsa: "M4R", from: [43.7040, -79.4000], to: [43.6990, -79.4300], numbers: 100..1000),
    # North and east suburbs
    Segment.new(name: "Kennedy Rd", fsa: "M1P", from: [43.7300, -79.2650], to: [43.7800, -79.2800], numbers: 1..3000),
    Segment.new(name: "Lawrence Ave E", fsa: "M1P", from: [43.7300, -79.3050], to: [43.7500, -79.2300], numbers: 1000..3500),
    Segment.new(name: "Sheppard Ave W", fsa: "M3H", from: [43.7590, -79.4100], to: [43.7480, -79.4700], numbers: 100..1400),
    # Etobicoke
    Segment.new(name: "Bloor St W", fsa: "M8X", from: [43.6470, -79.4900], to: [43.6400, -79.5400], numbers: 2800..4000),
    Segment.new(name: "Royal York Rd", fsa: "M8Y", from: [43.6350, -79.5100], to: [43.6600, -79.5180], numbers: 100..1000),
    # Mississauga, for the outer zone
    Segment.new(name: "Hurontario St", fsa: "L5B", from: [43.5890, -79.6440], to: [43.6200, -79.6600], numbers: 1..4000, city: "Mississauga"),
    Segment.new(name: "Lakeshore Rd E", fsa: "L5G", from: [43.5860, -79.6050], to: [43.5750, -79.5700], numbers: 1..1500, city: "Mississauga")
    ].freeze
  end
end
