#include <hxcpp.h>
#include <hx/Scriptable.h>
#include <stdio.h>
#include <vector>
#include <map>

namespace hx
{

enum Type { nsPublic, nsPrivate, nsNamespace, nsInternal, nsProtected, nsExplicit, nsStaticProtected };

enum MultiNameKind
{
   QNNone       = 0x00,
   QName        = 0x07,
   QNameA       = 0x0D,
   RTQName      = 0x0F,
   RTQNameA     = 0x10,
   RTQNameL     = 0x11,
   RTQNameLA    = 0x12,
   Multiname    = 0x09,
   MultinameA   = 0x0E,
   MultinameL   = 0x1B,
   MultinameLA  = 0x1C,
};

enum MethodFlags
{
   NEED_ARGUMENTS  = 0x01,
   NEED_ACTIVATION = 0x02,
   NEED_REST       = 0x04,
   HAS_OPTIONAL    = 0x08,
   SET_DXNS        = 0x40,
   HAS_PARAM_NAMES = 0x80,
};

enum TraitKind
{
   Trait_Slot    = 0,
   Trait_Method  = 1,
   Trait_Getter  = 2,
   Trait_Setter  = 3,
   Trait_Class   = 4,
   Trait_Function= 5,
   Trait_Const   = 6,
};

enum TraitAttr
{
   ATTR_Final    = 0x10,
   ATTR_Override = 0x20,
   ATTR_Metadata = 0x40,
};

enum InstanceFlags
{
   ClassSealed      = 0x01,
   ClassFinal       = 0x02,
   ClassInterface   = 0x04,
   ClassProtectedNs = 0x08,
};

struct Namespace
{
   Type type;
   int  index;
};

struct MultiName
{
   MultiName() : kind(QNNone), ns(0), name(0), ns_set(0) { }
   MultiNameKind kind;
   int           ns;
   int           name;
   int           ns_set;
};


typedef std::vector<Namespace> NsSet;

struct Optional
{
   int val;
   int kind;
};

struct Method
{
   int paramCount;
   int returnType;
   std::vector<int> paramTypes;
   int name;
   int flags;
   std::vector<Optional> optionals;
   std::vector<int> paramNames;
};

struct KeyValue
{
   int key;
   int value;
};

struct MetaData
{
   int name;
   std::vector<KeyValue> data;
};

struct TraitSlot
{
   int slot;
   int typeName;
   int index;
   int vkind;
};

struct Trait
{
   int       name;
   int       flags;
   TraitKind kind;

   int slot;
   int type;
   int index;
   int vkind;

   std::vector<int> metaData;
};


struct InstanceInfo
{
   int name;
   int superName;
   int flags;
   int protectedNs;
   std::vector<int> interfaces;
   int iinit;
   std::vector<Trait> traits;
};


struct TraitSet
{
   int init;
   std::vector<Trait> traits;
};

struct ExceptionInfo
{
   int from;
   int to;
   int target;
   int excType;
   int varName;
};

struct MethodBody
{
   int method;
   int maxStack;
   int localCount;
   int initScopeDepth;
   int maxScopeDepth;
   std::vector<unsigned char> code;
   std::vector<ExceptionInfo> exception;
   std::vector<Trait> traits;
};



struct ABC
{
   std::vector<int> mInts;
   std::vector<unsigned int> mUInts;
   std::vector<double> mDoubles;
   std::vector<String> mStrings;
   std::vector<Namespace> mNamespaces;
   std::vector<NsSet> mNsSets;
   std::vector<MultiName> mMultiNames;

   std::vector<Method> mMethods;
   std::vector<MetaData> mMetaData;
   std::vector<InstanceInfo> mInstanceInfo;
   std::vector<TraitSet> mClassInfo;
   std::vector<TraitSet> mScriptInfo;

   std::vector<MethodBody> mMethodBody;
};


struct ABCReader
{
   const unsigned char *ptr;
   const unsigned char *end;
   const char *error;
   ABC &abc;

   ABCReader(ABC &inAbc,const unsigned char *inPtr, int inLen) : abc(inAbc)
   {
      ptr = inPtr;
      end = ptr+inLen;
      error = 0;
   }

   int readByte()
   {
      if (ptr>=end)
        setError("Past EOF");
      if (error)
         return 0;
      return *ptr++;
   }

   bool ok() { return !error; }

   void setError(const char *inError) { error = inError; }
      
	int readInt()
   {
		int a = readByte();
		if( a < 128 )
			return a;
		a &= 0x7F;
		int b = readByte();
		if( b < 128 )
			return (b << 7) | a;
		b &= 0x7F;
		int c = readByte();
		if( c < 128 )
			return (c << 14) | (b << 7) | a;
		c &= 0x7F;
		int d = readByte();
		if( d < 128 )
			return (d << 21) | (c << 14) | (b << 7) | a;
		d &= 0x7F;
		int e = readByte();
		if( e > 15 ) setError("bad integer encoding");
		return (e << 28) | (d << 21) | (c << 14) | (b << 7) | a;
	}
	int readUInt30()
   {
		int ch1 = readByte();
		int ch2 = readByte();
		int ch3 = readByte();
		int ch4 = readByte();
		if( ch4 >= 64 ) setError("Uint30 out of bounds");
		return  ch1 | (ch2 << 8) | (ch3 << 16) | (ch4 << 24);
	}

   void read(int &i) { i = readInt(); }
   void read(unsigned int &i) { i = readInt(); }
   void read(double &d)
   {
      if (ptr+8>=end)
         setError("EOF");
      else 
      {
         memcpy(&d,ptr,sizeof(double));
         ptr+=8;
      }
   }
   void read(String &s)
   {
      int len = readInt();
      if (ptr+len>=end)
         setError("string too long");
      else
      {
         s = String((char *)ptr,len).dup();
         ptr+=len;
      }
   }
	void read(Namespace &ns)
   {
		switch(readByte())
      {
		   case 0x05: ns.type = nsPrivate; break;
		   case 0x08: ns.type = nsNamespace; break;
		   case 0x16: ns.type = nsPublic; break;
		   case 0x17: ns.type = nsInternal; break;
		   case 0x18: ns.type = nsProtected; break;
		   case 0x19: ns.type = nsExplicit; break;
		   case 0x1A: ns.type = nsStaticProtected; break;
		   default: setError("unknown namespace type");
		}
      ns.index = readInt();
   }
	void read(MultiName &mn)
   {
      mn.kind = (MultiNameKind)readByte();
      switch(mn.kind)
      {
         case QName      :
         case QNameA     :
             mn.ns = readByte();
             mn.name = readByte();
             break;
         case RTQName    :
             mn.name = readByte();
             break;
         case RTQNameA   :
         case RTQNameL   :
         case RTQNameLA  :
             break;
         case Multiname  :
         case MultinameA :
             mn.name = readByte();
             mn.ns_set = readByte();
             break;
         case MultinameL :
         case MultinameLA:
             mn.ns_set = readByte();
             break;
         default:
             setError("Unknown multi-name constant");
      }
   }

   void read(Optional &optional)
   {
      optional.val = readInt();
      optional.kind = readByte();
   }

   void read(Method &method)
   {
      method.paramCount = readInt();
      method.returnType = readInt();
      readFull(method.paramTypes,method.paramCount);
      method.name = readInt();
      method.flags = readByte();
      if (method.flags & HAS_OPTIONAL)
         readFull(method.optionals,readInt());
      if (method.flags & HAS_PARAM_NAMES)
         readFull(method.paramNames,method.paramCount);
   }

   void read(KeyValue &value)
   {
      value.key = readInt();
      value.value = readInt();
   }

   void read(MetaData &meta)
   {
      meta.name = readInt();
      readFull(meta.data);
   }


   void read(ExceptionInfo &ex)
   {
      ex.from = readInt();
      ex.to = readInt();
      ex.target = readInt();
      ex.excType = readInt();
      ex.varName = readInt();
   }
   inline void read(unsigned char &byte) { byte = readByte(); }

   void read(MethodBody &body)
   {
      body.method = readInt();
      body.maxStack = readInt();
      body.localCount = readInt();
      body.initScopeDepth = readInt();
      body.maxScopeDepth = readInt();
      readFull(body.code);
      readFull(body.exception);
      readFull(body.traits);
   }



   void read(Trait &trait)
   {
      trait.name = readInt();
      trait.flags = readByte();
      trait.kind = (TraitKind)(trait.flags & 0x0f);
      switch(trait.kind)
      {
         case Trait_Slot:
         case Trait_Const:
            trait.slot = readInt();
            trait.type = readInt();
            trait.index = readInt();
            if (trait.index==0)
               trait.vkind = 0;
            else
               trait.vkind = readByte();
            break;
         case Trait_Method:
         case Trait_Getter:
         case Trait_Setter:
            trait.slot = readInt();
            trait.index = readInt();
            break;
         case Trait_Class:
            trait.slot = readInt();
            trait.index = readInt();
            break;
         case Trait_Function:
            trait.slot = readInt();
            trait.index = readInt();
            break;
         default:
            setError("Unknown trait type");
      }

      if (trait.flags & ATTR_Metadata)
      {
         readFull(trait.metaData);
      }
   }

   void read(InstanceInfo &inst)
   {
      inst.name = readInt();
      printf("Instance Name : %s\n", abc.mStrings[ abc.mMultiNames[inst.name].name].__s);
      inst.superName = readInt();
      inst.flags = readByte();
      if (inst.flags & ClassProtectedNs)
         inst.protectedNs = readInt();
      readFull(inst.interfaces);
      inst.iinit = readInt();
      readFull(inst.traits);
   }


   void read(TraitSet &ts)
   {
      ts.init = readInt();
      readFull(ts.traits);
   }



   template<typename T>
   void read(std::vector<T> &list)
   {
      int n = readInt();
      if (n==0)
         n = 1;
         
      list.resize(n);
      for(int i=1;i<n;i++)
         read(list[i]);
   }


   template<typename T>
   void readFull(std::vector<T> &list,int inN=-1)
   {
      int n = inN<0 ? readInt() : inN;
         
      list.resize(n);
      for(int i=0;i<n;i++)
         read(list[i]);
   }


   void read(ABC &abc)
   {
      read(abc.mInts);
      read(abc.mUInts);
      read(abc.mDoubles);
      read(abc.mStrings);
      read(abc.mNamespaces);
      read(abc.mNsSets);
      read(abc.mMultiNames);

      readFull(abc.mMethods);
      readFull(abc.mMetaData);

      int classes = readInt();

      readFull(abc.mInstanceInfo,classes);
      readFull(abc.mClassInfo,classes);
      readFull(abc.mScriptInfo);

      readFull(abc.mMethodBody);

      printf("Result : %s\n", error );

   }


};

void LoadABC(const unsigned char *inBytes, int inLen)
{
   ABC abc;
   ABCReader stream(abc, inBytes,inLen);

   int version = stream.readUInt30();
   if (version!= 0x002E0010 )
   {
      printf("Unknown version\n");
      return;
   }

   stream.read(abc);
   
    
}




enum OpCode
{
   opAccNull,
   opAccTrue,
   opAccFalse,
   opAccThis,
   opAccInt,
   opAccStack,
   opAccGlobal,
   opAccEnv,
   opAccField,
   opAccArray,
   opAccIndex,
   opAccBuiltin,
   opSetStack,
   opSetGlobal,
   opSetEnv,
   opSetField,
   opSetArray,
   opSetIndex,
   opSetThis,
   opPush,
   opPop,
   opCall,
   opObjCall,
   opJump,
   opJumpIf,
   opJumpIfNot,
   opTrap,
   opEndTrap,
   opRet,
   opMakeEnv,
   opMakeArray,
   opBool,
   opIsNull,
   opIsNotNull,
   opAdd,
   opSub,
   opMult,
   opDiv,
   opMod,
   opShl,
   opShr,
   opUShr,
   opOr,
   opAnd,
   opXor,
   opEq,
   opNeq,
   opGt,
   opGte,
   opLt,
   opLte,
   opNot,
   opTypeOf,
   opCompare,
   opHash,
   opNew,
   opJumpTable,
   opApply,
   opAccStack0,
   opAccStack1,
   opAccIndex0,
   opAccIndex1,
   opPhysCompare,
   opTailCall,

   opLast,
};


const char *opNames[] =
{
   "opAccNull",
   "opAccTrue",
   "opAccFalse",
   "opAccThis",
   "opAccInt",
   "opAccStack",
   "opAccGlobal",
   "opAccEnv",
   "opAccField",
   "opAccArray",
   "opAccIndex",
   "opAccBuiltin",
   "opSetStack",
   "opSetGlobal",
   "opSetEnv",
   "opSetField",
   "opSetArray",
   "opSetIndex",
   "opSetThis",
   "opPush",
   "opPop",
   "opCall",
   "opObjCall",
   "opJump",
   "opJumpIf",
   "opJumpIfNot",
   "opTrap",
   "opEndTrap",
   "opRet",
   "opMakeEnv",
   "opMakeArray",
   "opBool",
   "opIsNull",
   "opIsNotNull",
   "opAdd",
   "opSub",
   "opMult",
   "opDiv",
   "opMod",
   "opShl",
   "opShr",
   "opUShr",
   "opOr",
   "opAnd",
   "opXor",
   "opEq",
   "opNeq",
   "opGt",
   "opGte",
   "opLt",
   "opLte",
   "opNot",
   "opTypeOf",
   "opCompare",
   "opHash",
   "opNew",
   "opJumpTable",
   "opApply",
   "opAccStack0",
   "opAccStack1",
   "opAccIndex0",
   "opAccIndex1",
   "opPhysCompare",
   "opTailCall",

   "opLast",
};



class NekoModule
{
public:
   NekoModule(const char *inFilename)
   {
      mGlobalCount = 0;
      mFieldCount = 0;
      mCodeSize = 0;
      mOpCodes = 0;
      mOk = false;

      FILE *file = fopen(inFilename,"rb");
      if (!file)
      {
         printf("Could not load module: %s\n", inFilename);
      }
      else
      {
         mFile = file;
         try {
            Load(file);
         }
         catch (const char *inError)
         {
            printf("Error on load : %s\n", inError);
         }
         mFile = 0;
         fclose(file);
      }
   }

   ~NekoModule()
   {
      delete [] mOpCodes;
   }

   void DumpOp(const int *inOp)
   {
      int idx = inOp - mOpCodes;
      int arg = inOp[1];
      printf(" %03d %s", idx, opNames[*inOp]);
      switch(*inOp)
      {
         case opAccField:
            {
            unsigned int fid = mFieldHash[arg & 0x7fffffff];
            printf(" %s", mFields[fid].__s);
            break;
            }
         case opAccGlobal:
            if (arg>=mGlobalCount || arg<0)
               printf(" %d ???", arg );
            else
               printf(" %s", !mGlobals[arg].mPtr ? "(null)" : mGlobals[arg]->__ToString().c_str() );
            break;
      }
      printf("\n", idx, opNames[*inOp]);
   }

   void Error(const char *inMsg)
   {
      throw inMsg;
   }

   int ReadByte()
   {
      unsigned char byte;
      if (fread(&byte,1,1,mFile)!=1)
         Error("Unexpected end of stream");
      return byte;
   }

   int ReadInt()
   {
      int i;
      if (fread(&i,4,1,mFile)!=1)
         Error("Unexpected end of stream");
      return i;
   }

   int ReadUInt16()
   {
      unsigned short i;
      if (fread(&i,2,1,mFile)!=1)
         Error("Unexpected end of stream");
      return i;
   }


   const char *ReadString()
   {
      int i = 0;
      char c;
      while( i < sizeof(mStringBuf) )
      {
         char c = ReadByte();
         mStringBuf[i++] = c;
         if( c == 0 )
            return mStringBuf;
      }
      Error("Unterminated string");
      return "";
   }

   Dynamic ReadString16()
   {
      int len = ReadUInt16();
      if (len==0)
         return String("",0).dup();

      char *buffer = (char *)malloc(len);
      if (fread(buffer,len,1,mFile)!=1)
      {
         free(buffer);
         Error("Could not read string16");
      }
      Dynamic result = String(buffer,len).dup();
      free(buffer);
      return result;
   }


   void ReadDebugInfo()
   {
      bool lot_of_files = false;
      int nfiles = 0;

      // TODO:
      int c = ReadByte();
      if( c >= 0x80 )
      {
         int c2 = ReadByte();
         nfiles = ((c & 0x7F) << 8) | c2;
         lot_of_files = true;
      } else
         nfiles = c;

      if( nfiles == 0 )
         Error("No debug files");

      for(int i=0;i<nfiles;i++)
         ReadString();

      int npos = ReadInt();
      if( npos != mCodeSize )
         Error("Code size mismatch");

      int i = 0;
      while( i < npos )
      {
         int c = ReadByte();
         if( c & 1 )
         {
            if( lot_of_files )
               ReadByte();
         }
         else if( c & 2 )
         {
            int delta = c >> 6;
            int count = (c >> 2) & 15;
            if( i + count > npos )
               Error("Bad line count");
            i+= count;
         }
         else if( c & 4 )
         {
            i++;
         }
         else
         {
            unsigned char b2 = ReadByte();
            unsigned char b3 = ReadByte();
            i++;
         }
      }
   }

   unsigned int NekoHash(const char *name)
   {
      unsigned int result = 0;
	   while( *name )
      {
		  result = (223 * result + *((unsigned char*)name));
		  name++;
	   }
      return result & 0x7fffffff;
   }


   void Load(FILE *inFile)
   {
      unsigned int magic;
      fread(&magic,4,1,inFile);
      if (magic!=0x4F4B454E)
         Error("Bad Magic");

      mGlobalCount = ReadInt();
      mFieldCount = ReadInt();
      mCodeSize = ReadInt();

      printf("globs=%d, fields=%d, code=%d\n", mGlobalCount, mFieldCount, mCodeSize );
      mGlobals = Array_obj<Dynamic>::__new(mGlobalCount, mGlobalCount);

      for(int g=0;g<mGlobalCount;g++)
      {
         switch(ReadByte())
         {
            case 1:
               mGlobals[g] = String(ReadString()).dup();
               // null
               break;

            case 2:
               {
               int combined = ReadInt();
               int pos = combined &0xffffff;
               int extra = combined >> 24;
               if (pos>=mCodeSize)
                  Error("Bad code size");
               mGlobals[g] = String("Function @") + String(pos);
               break;
               }

            case 3:
               mGlobals[g] = ReadString16();
               break;

            case 4:
               mGlobals[g] = atof(ReadString());
               break;

            case 5:
               ReadDebugInfo();
               break;

            default:
               Error("Unknown global code");
         }
      }
      printf("Read globals %d\n",mGlobalCount);

      printf("Read fields...\n");
      mFields = Array_obj<String>::__new(mFieldCount);
      for(int f=0;f<mFieldCount;f++)
      {
         mFields[f] = String(ReadString()).dup();
         unsigned int id = NekoHash( mFields[f].__s );
         mFieldHash[id] = f;
         printf(" %08x -> %d\n", id,f );
      }
      printf("Read fields\n");

      printf("Unpack op codes...\n");

      int idx = 0;
      // Unpack opcodes
      mOpCodes = new int[mCodeSize+1];
      while( idx < mCodeSize )
      {
         int t = ReadByte();
         switch( t & 3 )
         {
         case 0:
            mOpCodes[idx++] = (t >> 2);
            DumpOp(mOpCodes+idx-1);
            break;
         case 1:
            mOpCodes[idx++] = (t >> 3);
            mOpCodes[idx++] = (t >> 2) & 1;
            DumpOp(mOpCodes+idx-2);
            break;
         case 2:
            mOpCodes[idx++] = (t >> 2);
            mOpCodes[idx++] = ReadByte();
            DumpOp(mOpCodes+idx-2);
            break;
         case 3:
            mOpCodes[idx++] = (t >> 2);
            mOpCodes[idx++] = ReadInt();
            DumpOp(mOpCodes+idx-2);
            break;
         }
      }
      mOpCodes[idx] = opLast;
      mEntry = (int)mOpCodes[1];
      printf("Read %d op codes\n",idx);
   }

   Array<Dynamic> mGlobals;
   Array<String>  mFields;
   std::map<unsigned int,int> mFieldHash;

   bool mOk;
   int mGlobalCount;
   int mFieldCount;
   int mCodeSize;
   int mEntry;
   int *mOpCodes;
   char mStringBuf[256];
   FILE *mFile;
};


void ScriptableRegisterClass( String inName, String *inFunctions, hx::ScriptableClassFactory inFactory)
{
}


void ScriptableRegisterInterface( String inName, const type_info *inType, hx::ScriptableInterfaceFactory inFactory)
{
}



Dynamic ScriptableCall0(void *user, Object *thiz)
{
   return null();
}

Dynamic ScriptableCall1(void *user, Object *thiz,Dynamic)
{
   return null();
}

Dynamic ScriptableCall2(void *user, Object *thiz,Dynamic,Dynamic)
{
   return null();
}

Dynamic ScriptableCall3(void *user, Object *thiz,Dynamic,Dynamic,Dynamic)
{
   return null();
}

Dynamic ScriptableCall4(void *user, Object *thiz,Dynamic,Dynamic,Dynamic,Dynamic)
{
   return null();
}

Dynamic ScriptableCall5(void *user, Object *thiz,Dynamic,Dynamic,Dynamic,Dynamic,Dynamic)
{
   return null();
}

Dynamic ScriptableCallMult(void *user, Object *thiz,Dynamic *inArgs)
{
   return null();
}


} // end namespace hx

void __scriptable_load_neko(String inName)
{
   new hx::NekoModule(inName.__s);
}


void __scriptable_load_abc(Array<unsigned char> inBytes)
{
   hx::LoadABC(&inBytes[0], inBytes->length);
}
