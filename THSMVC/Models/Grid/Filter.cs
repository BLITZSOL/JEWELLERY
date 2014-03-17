﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Json;
using System.Text;


namespace THSMVC.Models.Grid
{
    [DataContract]
    public class Filter
    {
        [DataMember]
        public string groupOp { get; set; }
        [DataMember]
        public Rule[] rules { get; set; }

        public static Filter Create(string jsonData)
        {
            try
            {
                var serializer = new DataContractJsonSerializer(typeof(Filter));
               // System.IO.StringReader reader = new System.IO.StringReader(jsonData);
                using (System.IO.MemoryStream ms =
                     new System.IO.MemoryStream(Encoding.Default.GetBytes(jsonData)))
                {
                    return serializer.ReadObject(ms) as Filter;
                }
            }
            catch
            {
                return null;
            }
        }
    }
}