export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.18"
  }
  public: {
    Tables: {
      ai_jobs: {
        Row: {
          cost_cents: number
          created_at: string
          created_by: string
          error: string | null
          family_id: string
          finished_at: string | null
          id: string
          kind: string
          model: string | null
          status: string
          target_id: string | null
        }
        Insert: {
          cost_cents?: number
          created_at?: string
          created_by?: string
          error?: string | null
          family_id: string
          finished_at?: string | null
          id?: string
          kind: string
          model?: string | null
          status?: string
          target_id?: string | null
        }
        Update: {
          cost_cents?: number
          created_at?: string
          created_by?: string
          error?: string | null
          family_id?: string
          finished_at?: string | null
          id?: string
          kind?: string
          model?: string | null
          status?: string
          target_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "ai_jobs_family_id_fkey"
            columns: ["family_id"]
            isOneToOne: false
            referencedRelation: "families"
            referencedColumns: ["id"]
          },
        ]
      }
      albums: {
        Row: {
          created_at: string
          description: string | null
          family_id: string
          id: string
          title: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          family_id: string
          id?: string
          title: string
        }
        Update: {
          created_at?: string
          description?: string | null
          family_id?: string
          id?: string
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "albums_family_id_fkey"
            columns: ["family_id"]
            isOneToOne: false
            referencedRelation: "families"
            referencedColumns: ["id"]
          },
        ]
      }
      app_settings: {
        Row: {
          key: string
          updated_at: string
          value: Json
        }
        Insert: {
          key: string
          updated_at?: string
          value: Json
        }
        Update: {
          key?: string
          updated_at?: string
          value?: Json
        }
        Relationships: []
      }
      audit_log: {
        Row: {
          action: string
          actor: string | null
          created_at: string
          details: Json | null
          entity: string | null
          entity_id: string | null
          id: string
        }
        Insert: {
          action: string
          actor?: string | null
          created_at?: string
          details?: Json | null
          entity?: string | null
          entity_id?: string | null
          id?: string
        }
        Update: {
          action?: string
          actor?: string | null
          created_at?: string
          details?: Json | null
          entity?: string | null
          entity_id?: string | null
          id?: string
        }
        Relationships: []
      }
      book_options: {
        Row: {
          active: boolean
          code: string
          id: string
          kind: string
          label: string
          position: number
          surcharge_cents: number
        }
        Insert: {
          active?: boolean
          code: string
          id?: string
          kind: string
          label: string
          position?: number
          surcharge_cents?: number
        }
        Update: {
          active?: boolean
          code?: string
          id?: string
          kind?: string
          label?: string
          position?: number
          surcharge_cents?: number
        }
        Relationships: []
      }
      book_sections: {
        Row: {
          body: string | null
          created_at: string
          family_id: string
          id: string
          photo_ids: string[]
          position: number
          story_ids: string[]
          title: string
        }
        Insert: {
          body?: string | null
          created_at?: string
          family_id: string
          id?: string
          photo_ids?: string[]
          position?: number
          story_ids?: string[]
          title: string
        }
        Update: {
          body?: string | null
          created_at?: string
          family_id?: string
          id?: string
          photo_ids?: string[]
          position?: number
          story_ids?: string[]
          title?: string
        }
        Relationships: [
          {
            foreignKeyName: "book_sections_family_id_fkey"
            columns: ["family_id"]
            isOneToOne: false
            referencedRelation: "families"
            referencedColumns: ["id"]
          },
        ]
      }
      consent_log: {
        Row: {
          created_at: string
          family_id: string | null
          granted: boolean
          id: string
          kind: string
          user_id: string
        }
        Insert: {
          created_at?: string
          family_id?: string | null
          granted: boolean
          id?: string
          kind: string
          user_id?: string
        }
        Update: {
          created_at?: string
          family_id?: string | null
          granted?: boolean
          id?: string
          kind?: string
          user_id?: string
        }
        Relationships: []
      }
      documents: {
        Row: {
          corrected_text: string | null
          created_at: string
          created_by: string
          family_id: string
          id: string
          language: string | null
          needs_review: boolean
          ocr_confidence: string | null
          ocr_text: string | null
          size_bytes: number
          storage_path: string | null
          title: string
          translation: string | null
          year: number | null
        }
        Insert: {
          corrected_text?: string | null
          created_at?: string
          created_by?: string
          family_id: string
          id?: string
          language?: string | null
          needs_review?: boolean
          ocr_confidence?: string | null
          ocr_text?: string | null
          size_bytes?: number
          storage_path?: string | null
          title: string
          translation?: string | null
          year?: number | null
        }
        Update: {
          corrected_text?: string | null
          created_at?: string
          created_by?: string
          family_id?: string
          id?: string
          language?: string | null
          needs_review?: boolean
          ocr_confidence?: string | null
          ocr_text?: string | null
          size_bytes?: number
          storage_path?: string | null
          title?: string
          translation?: string | null
          year?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "documents_family_id_fkey"
            columns: ["family_id"]
            isOneToOne: false
            referencedRelation: "families"
            referencedColumns: ["id"]
          },
        ]
      }
      families: {
        Row: {
          created_at: string
          description: string | null
          face_grouping_consent: boolean
          id: string
          name: string
          owner_id: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          face_grouping_consent?: boolean
          id?: string
          name: string
          owner_id: string
        }
        Update: {
          created_at?: string
          description?: string | null
          face_grouping_consent?: boolean
          id?: string
          name?: string
          owner_id?: string
        }
        Relationships: []
      }
      family_members: {
        Row: {
          created_at: string
          family_id: string
          role: Database["public"]["Enums"]["family_role"]
          user_id: string
        }
        Insert: {
          created_at?: string
          family_id: string
          role?: Database["public"]["Enums"]["family_role"]
          user_id: string
        }
        Update: {
          created_at?: string
          family_id?: string
          role?: Database["public"]["Enums"]["family_role"]
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "family_members_family_id_fkey"
            columns: ["family_id"]
            isOneToOne: false
            referencedRelation: "families"
            referencedColumns: ["id"]
          },
        ]
      }
      invitations: {
        Row: {
          accepted_at: string | null
          created_at: string
          created_by: string
          email: string
          expires_at: string
          family_id: string
          id: string
          role: Database["public"]["Enums"]["family_role"]
          token: string
        }
        Insert: {
          accepted_at?: string | null
          created_at?: string
          created_by: string
          email: string
          expires_at?: string
          family_id: string
          id?: string
          role?: Database["public"]["Enums"]["family_role"]
          token?: string
        }
        Update: {
          accepted_at?: string | null
          created_at?: string
          created_by?: string
          email?: string
          expires_at?: string
          family_id?: string
          id?: string
          role?: Database["public"]["Enums"]["family_role"]
          token?: string
        }
        Relationships: [
          {
            foreignKeyName: "invitations_family_id_fkey"
            columns: ["family_id"]
            isOneToOne: false
            referencedRelation: "families"
            referencedColumns: ["id"]
          },
        ]
      }
      orders: {
        Row: {
          amount_cents: number
          created_at: string
          currency: string
          family_id: string | null
          id: string
          kind: string
          paid_at: string | null
          product_snapshot: Json
          provider_session_id: string | null
          shipping: Json | null
          status: string
          user_id: string
        }
        Insert: {
          amount_cents: number
          created_at?: string
          currency?: string
          family_id?: string | null
          id?: string
          kind: string
          paid_at?: string | null
          product_snapshot: Json
          provider_session_id?: string | null
          shipping?: Json | null
          status?: string
          user_id: string
        }
        Update: {
          amount_cents?: number
          created_at?: string
          currency?: string
          family_id?: string | null
          id?: string
          kind?: string
          paid_at?: string | null
          product_snapshot?: Json
          provider_session_id?: string | null
          shipping?: Json | null
          status?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "orders_family_id_fkey"
            columns: ["family_id"]
            isOneToOne: false
            referencedRelation: "families"
            referencedColumns: ["id"]
          },
        ]
      }
      people: {
        Row: {
          bio: string | null
          birth_approx: boolean
          birth_date: string | null
          birth_place: string | null
          created_at: string
          death_approx: boolean
          death_date: string | null
          family_id: string
          first_name: string
          gender: string | null
          id: string
          is_living: boolean
          is_minor: boolean
          last_name: string | null
        }
        Insert: {
          bio?: string | null
          birth_approx?: boolean
          birth_date?: string | null
          birth_place?: string | null
          created_at?: string
          death_approx?: boolean
          death_date?: string | null
          family_id: string
          first_name: string
          gender?: string | null
          id?: string
          is_living?: boolean
          is_minor?: boolean
          last_name?: string | null
        }
        Update: {
          bio?: string | null
          birth_approx?: boolean
          birth_date?: string | null
          birth_place?: string | null
          created_at?: string
          death_approx?: boolean
          death_date?: string | null
          family_id?: string
          first_name?: string
          gender?: string | null
          id?: string
          is_living?: boolean
          is_minor?: boolean
          last_name?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "people_family_id_fkey"
            columns: ["family_id"]
            isOneToOne: false
            referencedRelation: "families"
            referencedColumns: ["id"]
          },
        ]
      }
      photo_versions: {
        Row: {
          created_at: string
          error: string | null
          family_id: string
          id: string
          is_ai: boolean
          kind: string
          photo_id: string
          status: string
          storage_path: string | null
        }
        Insert: {
          created_at?: string
          error?: string | null
          family_id: string
          id?: string
          is_ai?: boolean
          kind: string
          photo_id: string
          status?: string
          storage_path?: string | null
        }
        Update: {
          created_at?: string
          error?: string | null
          family_id?: string
          id?: string
          is_ai?: boolean
          kind?: string
          photo_id?: string
          status?: string
          storage_path?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "photo_versions_family_id_fkey"
            columns: ["family_id"]
            isOneToOne: false
            referencedRelation: "families"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "photo_versions_photo_id_fkey"
            columns: ["photo_id"]
            isOneToOne: false
            referencedRelation: "photos"
            referencedColumns: ["id"]
          },
        ]
      }
      photos: {
        Row: {
          album_id: string | null
          created_at: string
          date_text: string | null
          description: string | null
          family_id: string
          id: string
          mime: string | null
          place: string | null
          size_bytes: number
          storage_path: string
          tags: string[]
          title: string | null
          uploaded_by: string
          year: number | null
        }
        Insert: {
          album_id?: string | null
          created_at?: string
          date_text?: string | null
          description?: string | null
          family_id: string
          id?: string
          mime?: string | null
          place?: string | null
          size_bytes?: number
          storage_path: string
          tags?: string[]
          title?: string | null
          uploaded_by?: string
          year?: number | null
        }
        Update: {
          album_id?: string | null
          created_at?: string
          date_text?: string | null
          description?: string | null
          family_id?: string
          id?: string
          mime?: string | null
          place?: string | null
          size_bytes?: number
          storage_path?: string
          tags?: string[]
          title?: string | null
          uploaded_by?: string
          year?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "photos_album_id_fkey"
            columns: ["album_id"]
            isOneToOne: false
            referencedRelation: "albums"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "photos_family_id_fkey"
            columns: ["family_id"]
            isOneToOne: false
            referencedRelation: "families"
            referencedColumns: ["id"]
          },
        ]
      }
      price_history: {
        Row: {
          action: string
          changed_by: string | null
          created_at: string
          entity: string
          entity_id: string | null
          id: string
          new_data: Json | null
          old_data: Json | null
        }
        Insert: {
          action: string
          changed_by?: string | null
          created_at?: string
          entity: string
          entity_id?: string | null
          id?: string
          new_data?: Json | null
          old_data?: Json | null
        }
        Update: {
          action?: string
          changed_by?: string | null
          created_at?: string
          entity?: string
          entity_id?: string | null
          id?: string
          new_data?: Json | null
          old_data?: Json | null
        }
        Relationships: []
      }
      products: {
        Row: {
          active: boolean
          created_at: string
          currency: string
          description: string | null
          discount_percent: number
          features: string[]
          id: string
          interval: string | null
          kind: string
          limits: Json
          name: string
          position: number
          price_cents: number
          slug: string
          updated_at: string
        }
        Insert: {
          active?: boolean
          created_at?: string
          currency?: string
          description?: string | null
          discount_percent?: number
          features?: string[]
          id?: string
          interval?: string | null
          kind: string
          limits?: Json
          name: string
          position?: number
          price_cents: number
          slug: string
          updated_at?: string
        }
        Update: {
          active?: boolean
          created_at?: string
          currency?: string
          description?: string | null
          discount_percent?: number
          features?: string[]
          id?: string
          interval?: string | null
          kind?: string
          limits?: Json
          name?: string
          position?: number
          price_cents?: number
          slug?: string
          updated_at?: string
        }
        Relationships: []
      }
      profiles: {
        Row: {
          created_at: string
          display_name: string | null
          email: string | null
          id: string
        }
        Insert: {
          created_at?: string
          display_name?: string | null
          email?: string | null
          id: string
        }
        Update: {
          created_at?: string
          display_name?: string | null
          email?: string | null
          id?: string
        }
        Relationships: []
      }
      relationships: {
        Row: {
          created_at: string
          family_id: string
          id: string
          kind: string
          person_a: string
          person_b: string
        }
        Insert: {
          created_at?: string
          family_id: string
          id?: string
          kind: string
          person_a: string
          person_b: string
        }
        Update: {
          created_at?: string
          family_id?: string
          id?: string
          kind?: string
          person_a?: string
          person_b?: string
        }
        Relationships: [
          {
            foreignKeyName: "relationships_family_id_fkey"
            columns: ["family_id"]
            isOneToOne: false
            referencedRelation: "families"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_person_a_fkey"
            columns: ["person_a"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_person_b_fkey"
            columns: ["person_b"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
        ]
      }
      stories: {
        Row: {
          ai_chapter: string | null
          ai_questions: string | null
          approved: boolean
          audio_path: string | null
          created_at: string
          created_by: string
          family_id: string
          id: string
          narrator: string | null
          title: string
          transcript: string | null
          updated_at: string
          year: number | null
        }
        Insert: {
          ai_chapter?: string | null
          ai_questions?: string | null
          approved?: boolean
          audio_path?: string | null
          created_at?: string
          created_by?: string
          family_id: string
          id?: string
          narrator?: string | null
          title: string
          transcript?: string | null
          updated_at?: string
          year?: number | null
        }
        Update: {
          ai_chapter?: string | null
          ai_questions?: string | null
          approved?: boolean
          audio_path?: string | null
          created_at?: string
          created_by?: string
          family_id?: string
          id?: string
          narrator?: string | null
          title?: string
          transcript?: string | null
          updated_at?: string
          year?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "stories_family_id_fkey"
            columns: ["family_id"]
            isOneToOne: false
            referencedRelation: "families"
            referencedColumns: ["id"]
          },
        ]
      }
      user_roles: {
        Row: {
          id: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Insert: {
          id?: string
          role: Database["public"]["Enums"]["app_role"]
          user_id: string
        }
        Update: {
          id?: string
          role?: Database["public"]["Enums"]["app_role"]
          user_id?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      accept_invitation: { Args: { _token: string }; Returns: string }
      admin_ai_jobs: {
        Args: never
        Returns: {
          cost_cents: number
          created_at: string
          error: string
          id: string
          kind: string
          model: string
          status: string
        }[]
      }
      admin_families: {
        Args: never
        Returns: {
          created_at: string
          id: string
          members: number
          name: string
          owner_email: string
          photos: number
          storage_bytes: number
        }[]
      }
      admin_overview: { Args: never; Returns: Json }
      can_edit: { Args: { _family: string }; Returns: boolean }
      has_role: {
        Args: {
          _role: Database["public"]["Enums"]["app_role"]
          _user_id: string
        }
        Returns: boolean
      }
      is_member: { Args: { _family: string }; Returns: boolean }
      is_owner: { Args: { _family: string }; Returns: boolean }
    }
    Enums: {
      app_role: "admin" | "user"
      family_role: "owner" | "editor" | "viewer"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {
      app_role: ["admin", "user"],
      family_role: ["owner", "editor", "viewer"],
    },
  },
} as const