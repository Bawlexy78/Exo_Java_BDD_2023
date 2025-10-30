<%@ page import="java.util.*" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%!
    /** ========================
     *  POO : classe Task (attributs privés + getters/setters)
     *  ======================== */
    public static class Task implements java.io.Serializable {
        private final String id;
        private String title;
        private String description;
        private String dueDate; // yyyy-MM-dd
        private boolean done;

        public Task(String title, String description, String dueDate) {
            this.id = UUID.randomUUID().toString();
            this.title = title;
            this.description = description;
            this.dueDate = dueDate;
            this.done = false;
        }

        public String getId() { return id; }
        public String getTitle() { return title; }
        public String getDescription() { return description; }
        public String getDueDate() { return dueDate; }
        public boolean isDone() { return done; }

        public void setTitle(String title) { this.title = title; }
        public void setDescription(String description) { this.description = description; }
        public void setDueDate(String dueDate) { this.dueDate = dueDate; }
        public void setDone(boolean done) { this.done = done; }
    }

    /** Liste des tâches en session */
    @SuppressWarnings("unchecked")
    private static ArrayList<Task> getTasks(javax.servlet.http.HttpSession session) {
        Object o = session.getAttribute("tasks");
        if (o == null) {
            ArrayList<Task> list = new ArrayList<>();
            session.setAttribute("tasks", list);
            return list;
        }
        return (ArrayList<Task>) o;
    }

    /** Petit échappement HTML (pas de dépendance externe) */
    private static String esc(String s) {
        if (s == null) return "";
        StringBuilder sb = new StringBuilder();
        for (char c : s.toCharArray()) {
            switch (c) {
                case '&': sb.append("&amp;"); break;
                case '<': sb.append("&lt;"); break;
                case '>': sb.append("&gt;"); break;
                case '"': sb.append("&quot;"); break;
                case '\'': sb.append("&#39;"); break;
                default: sb.append(c);
            }
        }
        return sb.toString();
    }
%>
<%
    /* ========================
       Contrôleur minimal (tout-en-un)
       ======================== */
    request.setCharacterEncoding("UTF-8");
    ArrayList<Task> tasks = getTasks(session);

    String action = request.getParameter("action");
    if ("add".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
        String title = request.getParameter("title");
        String description = request.getParameter("description");
        String dueDate = request.getParameter("dueDate");
        if (title != null) title = title.trim();
        if (description == null) description = "";
        if (title != null && !title.isEmpty()) {
            tasks.add(new Task(title, description.trim(), dueDate));
        }
        response.sendRedirect("index.jsp"); // PRG: évite le repost au refresh
        return;
    }
    if ("del".equals(action)) {
        String id = request.getParameter("id");
        if (id != null) tasks.removeIf(t -> t.getId().equals(id));
        response.sendRedirect("index.jsp");
        return;
    }
    if ("toggle".equals(action)) {
        String id = request.getParameter("id");
        if (id != null) {
            for (Task t : tasks) {
                if (t.getId().equals(id)) { t.setDone(!t.isDone()); break; }
            }
        }
        response.sendRedirect("index.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title>Mini Gestionnaire de Tâches</title>
<style>
    :root { --b:#222; --g:#ddd; --m:#666; }
    body{font-family:Arial,Helvetica,sans-serif;margin:24px;line-height:1.4}
    h1{margin:0 0 12px}
    .muted{color:var(--m)}
    .btn{display:inline-block;padding:7px 12px;border:1px solid var(--b);text-decoration:none;background:#fff;cursor:pointer}
    form{max-width:720px;border:1px solid var(--g);padding:16px;margin:12px 0 24px}
    label{font-weight:bold;display:block;margin-top:8px}
    input[type="text"], textarea, input[type="date"]{width:100%;padding:8px;box-sizing:border-box}
    table{width:100%;border-collapse:collapse}
    th,td{border:1px solid var(--g);padding:8px;text-align:left;vertical-align:top}
    .done{text-decoration:line-through;color:var(--m)}
    .actions a{margin-right:6px}
</style>
</head>
<body>

<h1>Mini Gestionnaire de Tâches</h1>
<p class="muted">Application JSP simple • pas de base de données • stockage en session</p>

<!-- Formulaire d'ajout (HTML dans la JSP) -->
<form method="post" action="index.jsp?action=add" accept-charset="UTF-8">
    <div style="font-weight:bold;margin-bottom:6px;">Ajouter une tâche</div>
    <label for="title">Titre *</label>
    <input id="title" name="title" type="text" required>

    <label for="description">Description</label>
    <textarea id="description" name="description" rows="3"></textarea>

    <label for="dueDate">Date d’échéance</label>
    <input id="dueDate" name="dueDate" type="date">

    <div style="margin-top:10px;">
        <button class="btn" type="submit">Ajouter</button>
    </div>
</form>

<!-- Liste des tâches (boucle JSP) -->
<table>
    <thead>
        <tr>
            <th>Titre</th>
            <th>Description</th>
            <th>Échéance</th>
            <th>Statut</th>
            <th>Actions</th>
        </tr>
    </thead>
    <tbody>
    <%
        if (tasks.isEmpty()) {
    %>
        <tr><td colspan="5"><em>Aucune tâche pour le moment.</em></td></tr>
    <%
        } else {
            for (Task t : tasks) {
    %>
        <tr>
            <td class="<%= t.isDone() ? "done" : "" %>"><%= esc(t.getTitle()) %></td>
            <td class="<%= t.isDone() ? "done" : "" %>"><%= esc(t.getDescription()) %></td>
            <td class="<%= t.isDone() ? "done" : "" %>"><%= t.getDueDate() == null ? "" : esc(t.getDueDate()) %></td>
            <td><%= t.isDone() ? "Terminée" : "En cours" %></td>
            <td class="actions">
                <a class="btn" href="index.jsp?action=toggle&id=<%= esc(t.getId()) %>"><%= t.isDone() ? "Marquer non terminée" : "Marquer terminée" %></a>
                <a class="btn" href="index.jsp?action=del&id=<%= esc(t.getId()) %>" onclick="return confirm('Supprimer cette tâche ?');">Supprimer</a>
            </td>
        </tr>
    <%
            }
        }
    %>
    </tbody>
</table>

</body>
</html>

