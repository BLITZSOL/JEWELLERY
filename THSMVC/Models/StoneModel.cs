﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace THSMVC.Models
{
    public class StoneModel
    {

        public int Id { get; set; }
        public string StoneName { get; set; }
        public string StoneShortForm { get; set; }
        public int? StonePerCarat { get; set; }
        public bool IsStoneWeightless { get; set; }
        public string ChkStoneWeightless { get; set; }
        public string BtnText { get; set; }
        public int StoneId { get; set; }

    }
}